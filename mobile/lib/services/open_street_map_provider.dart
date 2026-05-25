import 'map_provider_interface.dart';

class OpenStreetMapProvider implements MapProviderInterface {
  const OpenStreetMapProvider();

  @override
  String get attributionText => 'OpenStreetMap contributors';

  @override
  String get tileUrlTemplate => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  String get userAgentPackageName => 'com.abhijnan.rakshati';
}
