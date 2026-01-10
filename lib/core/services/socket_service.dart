import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_admin/core/config/app_config.dart';

final socketServiceProvider = Provider((ref) => SocketService());

class SocketService {
  late IO.Socket socket;

  void init() {
    String url = AppConfig.apiUrl;
    // Remove '/api' suffix if present to get base URL
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - 4);
    } else if (url.endsWith('/api/')) {
      url = url.substring(0, url.length - 5);
    }

    // Disabled Socket.IO in favor of Firebase Realtime Streams
    // print('Connecting to Socket.io at $url');
    // socket = IO.io(url, IO.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build());
    // socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to Socket.io');
    });

    socket.onConnectError((data) => print('❌ Socket Connect Error: $data'));
    socket.onError((data) => print('❌ Socket Error: $data'));

    socket.onDisconnect((_) => print('Disconnected from Socket.io'));
  }

  void onNewOrder(Function(dynamic) callback) {
    socket.on('new_order', callback);
  }

  void dispose() {
    socket.dispose();
  }
}
