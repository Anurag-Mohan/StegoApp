import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:path_provider/path_provider.dart';

class P2PChatPage extends StatefulWidget {
  const P2PChatPage({super.key});

  @override
  State<P2PChatPage> createState() => _P2PChatPageState();
}

class _P2PChatPageState extends State<P2PChatPage> with WidgetsBindingObserver {
  final _p2p = FlutterP2pConnection();
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isHost = false;
  final String _roomName = "Room-${DateTime.now().millisecondsSinceEpoch % 1000}";
  List<DiscoveredPeers> _peers = [];
  WifiP2PInfo? _wifiP2PInfo;
  bool _isLoading = false;
  String? _downloadPath;
  bool _mounted = true;
  
 
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDownloadPath();
    _init();
  }

  Future<void> _initDownloadPath() async {
    final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    _downloadPath = directory.path;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _p2p.unregister();
    } else if (state == AppLifecycleState.resumed) {
      _p2p.register();
    }
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    
    try {
    
      await _p2p.askStoragePermission();
      await _p2p.askConnectionPermissions();
      
      
      await _p2p.initialize();
      await _p2p.register();
      
     
      bool isWifiEnabled = await _p2p.checkWifiEnabled();
      if (!isWifiEnabled) {
        await _p2p.enableWifiServices();
      }
      
      bool isLocationEnabled = await _p2p.checkLocationEnabled();
      if (!isLocationEnabled) {
        await _p2p.enableLocationServices();
      }
      
     
      _streamWifiInfo = _p2p.streamWifiP2PInfo().listen((info) {
        if (!_mounted) return;
        setState(() {
          _wifiP2PInfo = info;
          if (info.isConnected && info.groupOwnerAddress != null) {
            _addSystemMessage("Connected to group");
            
            
            if (info.isGroupOwner) {
              _startHostSocket(info.groupOwnerAddress);
            } else {
              _connectToHostSocket(info.groupOwnerAddress);
            }
          }
        });
      });
      
     
      _streamPeers = _p2p.streamPeers().listen((peers) {
        if (!_mounted) return;
        setState(() => _peers = peers);
      });
    } catch (e) {
      _addSystemMessage("Initialization error");
    } finally {
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addMessage(String text, bool isMe) {
    if (!_mounted) return;
    setState(() {
      _messages.add({
        "text": text,
        "isMe": isMe,
        "time": DateTime.now(),
        "isSystem": false
      });
      
     
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }
  
  void _addSystemMessage(String text) {
    if (!_mounted) return;
    setState(() {
      _messages.add({
        "text": text,
        "time": DateTime.now(),
        "isSystem": true
      });
      
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _startHostSocket(String ipAddress) async {
    await _p2p.startSocket(
      groupOwnerAddress: ipAddress,
      downloadPath: _downloadPath ?? "/storage/emulated/0/Download/",
      onConnect: (name, address) {
        _addSystemMessage("$name joined");
      },
      transferUpdate: (transfer) {
        
      },
      receiveString: (message) {
        _addMessage(message, false);
      },
      onCloseSocket: () {
        _addSystemMessage("Connection closed");
      },
    );
  }

  Future<void> _connectToHostSocket(String ipAddress) async {
    await _p2p.connectToSocket(
      groupOwnerAddress: ipAddress,
      downloadPath: _downloadPath ?? "/storage/emulated/0/Download/",
      onConnect: (address) {
        _addSystemMessage("Connected to room");
      },
      transferUpdate: (transfer) {
        
      },
      receiveString: (message) {
        _addMessage(message, false);
      },
      onCloseSocket: () {
        _addSystemMessage("Connection closed");
      },
    );
  }

  Future<void> _createRoom() async {
    if (!_mounted) return;
    setState(() => _isLoading = true);
    
    try {
      
      bool isWifiEnabled = await _p2p.checkWifiEnabled();
      if (!isWifiEnabled) {
        await _p2p.enableWifiServices();
        
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      bool success = await _p2p.createGroup();
      if (!_mounted) return;
      
      setState(() => _isHost = success);
      if (success) {
        _addSystemMessage("Room created: $_roomName");
      }
    } catch (e) {
      _addSystemMessage("Failed to create room");
    } finally {
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _discoverPeers() async {
    if (!_mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await _p2p.discover();
      _addSystemMessage("Searching for nearby devices...");
    } catch (e) {
      _addSystemMessage("Failed to discover peers");
    } finally {
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _stopDiscovery() async {
    await _p2p.stopDiscovery();
    _addSystemMessage("Stopped searching");
  }

  Future<void> _connectToPeer(DiscoveredPeers peer) async {
    if (!_mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await _p2p.connect(peer.deviceAddress);
      _addSystemMessage("Connecting to ${peer.deviceName}...");
    } catch (e) {
      _addSystemMessage("Failed to connect");
    } finally {
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _wifiP2PInfo == null || !_wifiP2PInfo!.isConnected) return;
    
    final text = _messageController.text;
    _messageController.clear();
    
    try {
      bool sent = await _p2p.sendStringToSocket(text);
      if (sent) {
        _addMessage(text, true);
      } else {
        _addSystemMessage("Failed to send message");
      }
    } catch (e) {
      _addSystemMessage("Failed to send message");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = _wifiP2PInfo != null && _wifiP2PInfo!.isConnected;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isHost ? "Host: $_roomName" : "P2P Chat"),
        elevation: 2,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _discoverPeers,
            tooltip: "Discover Peers",
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _stopDiscovery,
            tooltip: "Stop Discovery",
          ),
          if (!_isHost && (_wifiP2PInfo == null || !_wifiP2PInfo!.isConnected))
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _createRoom,
              tooltip: "Create Room",
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                if (_peers.isNotEmpty)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      itemCount: _peers.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ElevatedButton.icon(
                          onPressed: () => _connectToPeer(_peers[i]),
                          icon: const Icon(Icons.person_add),
                          label: Text(_peers[i].deviceName),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.blue.withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chat_bubble_outline, size: 72, color: Colors.blue.shade400),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _isHost ? "Waiting for people to join..." : "Join a room to start chatting",
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isHost 
                                    ? "Share your room with others nearby" 
                                    : "Tap on a discovered device or create your own room",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) => _buildMessage(_messages[i]),
                        ),
                ),
                _buildInputArea(isConnected),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Processing...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final time = msg['time'] as DateTime;
    final timeString = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    
  
    if (msg['isSystem'] == true) {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg['text'],
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    

    final isMe = msg['isMe'] as bool;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          color: isMe 
              ? Colors.blue.shade500 
              : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: isMe 
                  ? Colors.blue.shade300.withOpacity(0.4)
                  : Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: TextStyle(
                fontSize: 16,
                color: isMe ? Colors.white : Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeString,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: isConnected ? 'Type a message...' : 'Connect to chat...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                hintStyle: TextStyle(color: Colors.grey.shade500),
                suffixIcon: isConnected 
                    ? IconButton(
                        icon: Icon(Icons.send, color: Colors.blue.shade700),
                        onPressed: _sendMessage,
                      )
                    : Icon(Icons.send, color: Colors.grey.shade400),
              ),
              enabled: isConnected,
              textInputAction: TextInputAction.send,
              onSubmitted: isConnected ? (_) => _sendMessage() : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mounted = false;
    _streamWifiInfo?.cancel();
    _streamPeers?.cancel();
    _p2p.closeSocket();
    _p2p.removeGroup();
    _p2p.unregister();
    _messageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}