library flow;

import 'dart:collection';
import 'dart:async';
import 'dart:io';
import 'package:invocable/invocable.dart';
import 'package:hub/hub.dart';
import 'package:pipes/pipes.dart';
import 'package:ds/ds.dart' as d;


/*base class for flow */
abstract class FlowAbstract{
	void boot();
	void shutdown();
	void initalizeIPS();
	void addComponent();
	void addGraph();
	void removeComponent();
	void removeGraph();
}

/*base class for component*/
abstract class FlowComponent{

  void activate();
  void hibernate();
  void shutdown();

}

abstract class FlowSocket{
	void bind();
	void unbind();
	void beginGroup();
	void endGroup();
	void send();
	void end();
	void close();
	void attachPort(FlowPort port);
	void detachPort();
}

/*base class for ports*/
abstract class FlowPort{
  void connect();
  void send(data);
  void disconnect();
  void attach(FlowPort a);
  void unattach(FlowPort a);
}

//base class for IP (Information Packets)
abstract class FlowIP{
  dynamic get data;
  dynamic get id;
  dynamic get meta;
}


class Socket extends FlowSocket{
  final BufferedStream stream = BufferedStream.create();
  FlowPort from,to;
  bool _ong = false;
  bool _connected = false;
	
  static create(from,to) => new Socket(from,to);
  Socket(from,to){
    this.attach(from,to);
  }
  
  void attach(FlowPort from,FlowPort to){
    this.from = from;
    this.to = to;
    this.from.pipe.listen(this.stream.add);
    this.stream.listen(this.to.pipe.add);
    this.unbind();
  }

  void beginGroup(group){
    if(this._ong) return;
    this._ong = true;
    this.stream.buffer();
    this.stream.add(group);
  }

  void endGroup([groupend]){
    if(!this._ong) return;
    if(groupend != null) this.stream.add(groupend);
    this.stream.endBuffer();
    this._ong = false;
  }
  
  void send(data){
    this.stream.add(data);
  }

  void bind(){
    this._connected = true;
    this.stream.resume();
  }

  void unbind(){
    this._connected = false;
    this.stream.pause();
  }

  void close(){
    this._connected = false;
    this.to.pipe.disconnect();
    this.from.pipe.disconnect();
    this.from = this.to = null;
  }

  bool get isConnected => !!this._connected;
  bool get isDisconnected => !this._connected;
}
	
/*the channel for IP transmission on a component*/
class Port extends FlowPort{
  Streamable pipe;
  FlowSocket socket;
  String id;
  
  static create(id) => new Port(id);

  Port(this.id):super(){
    this.pipe = Streamable.create();
    this.binder.lock();
  }
  
  void beginGroup(data){
    if(this.socket == null) return;
    this.socket.beginGroup(data);
  }

  void send(data){
    if(this.socket == null) return;
    this.connect();
    this.socket.send(data);
    this.disconnect();
  }

  void endGroup([data]){
    if(this.socket == null) return;
    this.socket.endGroup(data);
  }
  
  void listen(Function n){
    this.pipe.listen(n);
  }

  void connect(){
    if(this.socket == null) return;
    this.socket.bind();
  }

  void disconnect(){
    if(this.socket == null) return;
    this.socket.unbind();
  }
  
  void attach(FlowPort a){
    if(this.socket != null) return;
    this.socket = new Socket(this,a);
  }

  void unattach(){
    if(this.socket == null) return;
    this.socket.unbind();
    this.socket.close();
    this.socket = null;
  }

  bool get isConnected{
    if(this.socket == null) return false;
    return this.socket.isConnected;
  }
  bool get isDisconnected {
    if(this.socket == null) return true;
    this.socket.isDisconnected; 
  }
}

class Flow extends FlowAbstract{

  static create() => new Flow();
  Flow();
}

class IP extends FlowIP{
  final zone = new MapDecorator();

  static create(id,Map meta,data) => new IP(id,meta,data);
  IP(id,meta,data){
    this.zone.add('data',data);
    this.zone.add('id',id);
    this.zone.add('meta',new MapDecorator.from(meta));
  }

  dynamic get Meta => this.zone.get('meta');
  dynamic get Data => this.zone.get('data');
  dynamic get ID => this.zone.get('id');

}

class FlowNetwork{
  d.ds
  static create() => new FlowNetwork();

}

/*class for component*/
class Component extends FlowComponent{
	bool _active = false;
  String id;

  static create(id) => new Component(id);
  Component();
  
  bool get active => !!this._active;
  bool get inActive => !this._active;
}
