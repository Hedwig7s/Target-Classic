import 'dart:io';
import 'package:buffer/buffer.dart';

class Connection {
  final int id;
  final Socket socket;
  ByteDataReader buffer = new ByteDataReader();
  bool closed = false;
  bool socketClosed = false;
  bool processingIncoming = false;

  Connection(this.id, this.socket) {
    socket.listen(
      (data) {
        buffer.add(data);
      },
      onDone: () {
        print('Client disconnected');
        socketClosed = true;
        if (closed) return;
        socket.close();
      },
      onError: (error) {
        this.onError(error);
      },
    );
  }
  onError(error) {
    print('Error: $error');
    if (closed) return;
    socket.close();
  }

  close() {
    if (closed) return;
    closed = true;
    if (socketClosed) return;
    print('Closing connection $id');
    socket.close();
  }
}
