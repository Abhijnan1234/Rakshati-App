import { randomBytes } from 'crypto';
import { Request, Response } from 'express';
import { Types } from 'mongoose';
import { z } from 'zod';
import {
  ConnectionDocument,
  ConnectionModel,
  RelationshipType,
} from '../models/Connection';
import {
  ConnectionInviteDocument,
  ConnectionInviteModel,
} from '../models/ConnectionInvite';
import { UserDocument, UserModel } from '../models/User';
import { AppError } from '../utils/appError';

const relationshipTypes = ['guardian', 'safeWalker'] as const satisfies readonly RelationshipType[];

const createInviteSchema = z.object({
  relationshipType: z.enum(relationshipTypes),
});

const acceptInviteSchema = z.object({
  token: z.string().trim().min(8, 'Invite token is required.'),
});

const reciprocalRelationship = (value: RelationshipType): RelationshipType =>
  value == 'guardian' ? 'safeWalker' : 'guardian';

const buildPairKey = (firstId: Types.ObjectId | string, secondId: Types.ObjectId | string) =>
  [String(firstId), String(secondId)].sort().join(':');

const serializeInvite = (invite: ConnectionInviteDocument) => ({
  id: invite.id,
  token: invite.token,
  relationshipType: invite.relationshipType,
  status: invite.status,
  expiresAt: invite.expiresAt,
  deepLink: `rakshati://invite/${invite.token}`,
  shareLink: `https://rakshati.app/invite/${invite.token}`,
});

const serializeConnection = (
  connection: ConnectionDocument,
  peer: UserDocument,
) => ({
  id: connection.id,
  relationshipType: connection.relationshipType,
  createdAt: connection.createdAt,
  lastUpdatedAt: connection.updatedAt,
  status: 'Connected',
  currentSafeWalkStatus: 'Idle',
  peer: {
    id: peer.id,
    username: peer.username,
    email: peer.email ?? null,
    authType: peer.authType,
  },
});

export const createInvite = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][Connections] POST /connections/invite userId=%s body=%o', req.user.id, req.body);
  try {
    const payload = createInviteSchema.parse(req.body);
    const invite = await ConnectionInviteModel.create({
      inviterId: req.user._id,
      relationshipType: payload.relationshipType,
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24),
      token: randomBytes(18).toString('hex'),
    });

    console.log('[Rakshati][Connections] Invite created token=%s', invite.token);
    res.status(201).json({
      invite: serializeInvite(invite),
    });
  } catch (error) {
    console.error('[Rakshati][Connections] Create invite failed:', error);
    throw error;
  }
};

export const acceptInvite = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][Connections] POST /connections/accept userId=%s body=%o', req.user.id, req.body);
  try {
    const payload = acceptInviteSchema.parse(req.body);
    const invite = await ConnectionInviteModel.findOne({
      token: payload.token,
    });

    if (!invite) {
      throw new AppError('Invite code was not found.', 404, 'INVITE_NOT_FOUND');
    }

    if (invite.inviterId.toString() == req.user.id) {
      throw new AppError('You cannot accept your own invite.', 400, 'INVITE_SELF');
    }

    if (invite.status != 'pending') {
      throw new AppError('This invite is no longer active.', 409, 'INVITE_INACTIVE');
    }

    if (invite.expiresAt.getTime() < Date.now()) {
      invite.status = 'expired';
      await invite.save();
      throw new AppError('This invite has expired.', 410, 'INVITE_EXPIRED');
    }

    const pairKey = buildPairKey(invite.inviterId, req.user._id);
    const alreadyConnected = await ConnectionModel.exists({ pairKey });
    if (alreadyConnected) {
      throw new AppError('You are already connected.', 409, 'ALREADY_CONNECTED');
    }

    await ConnectionModel.create([
      {
        ownerId: invite.inviterId,
        peerId: req.user._id,
        pairKey,
        relationshipType: invite.relationshipType,
        status: 'active',
      },
      {
        ownerId: req.user._id,
        peerId: invite.inviterId,
        pairKey,
        relationshipType: reciprocalRelationship(invite.relationshipType),
        status: 'active',
      },
    ]);

    invite.status = 'accepted';
    invite.acceptedBy = req.user._id;
    await invite.save();

    console.log('[Rakshati][Connections] Invite accepted token=%s pairKey=%s', invite.token, pairKey);
    res.status(201).json({
      success: true,
    });
  } catch (error) {
    console.error('[Rakshati][Connections] Accept invite failed:', error);
    throw error;
  }
};

export const getConnections = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][Connections] GET /connections userId=%s', req.user.id);
  try {
    const [connections, invites] = await Promise.all([
      ConnectionModel.find({
        ownerId: req.user._id,
        status: 'active',
      }).sort({ updatedAt: -1 }),
      ConnectionInviteModel.find({
        inviterId: req.user._id,
        status: 'pending',
        expiresAt: { $gt: new Date() },
      }).sort({ createdAt: -1 }),
    ]);

    const peerIds = connections.map((connection) => connection.peerId);
    const peers = await UserModel.find({
      _id: { $in: peerIds },
    });

    const peerMap = new Map(peers.map((peer) => [peer.id, peer]));
    const serialized = connections
      .map((connection) => {
        const peer = peerMap.get(connection.peerId.toString());
        return peer ? serializeConnection(connection, peer) : null;
      })
      .filter((value): value is NonNullable<typeof value> => value != null);

    res.status(200).json({
      guardians: serialized.filter((item) => item.relationshipType == 'guardian'),
      safeWalkers: serialized.filter((item) => item.relationshipType == 'safeWalker'),
      invites: invites.map(serializeInvite),
    });
  } catch (error) {
    console.error('[Rakshati][Connections] Fetch failed:', error);
    throw error;
  }
};

export const deleteConnection = async (req: Request, res: Response): Promise<void> => {
  console.log('[Rakshati][Connections] DELETE /connections/%s userId=%s', req.params.id, req.user.id);
  try {
    const connection = await ConnectionModel.findOne({
      _id: req.params.id,
      ownerId: req.user._id,
    });

    if (!connection) {
      throw new AppError('Connection not found.', 404, 'CONNECTION_NOT_FOUND');
    }

    await ConnectionModel.deleteMany({
      pairKey: connection.pairKey,
    });

    await ConnectionInviteModel.updateMany(
      {
        $or: [
          { inviterId: req.user._id, acceptedBy: connection.peerId },
          { inviterId: connection.peerId, acceptedBy: req.user._id },
        ],
        status: 'pending',
      },
      {
        status: 'cancelled',
      },
    );

    res.status(200).json({
      success: true,
    });
  } catch (error) {
    console.error('[Rakshati][Connections] Delete failed:', error);
    throw error;
  }
};
