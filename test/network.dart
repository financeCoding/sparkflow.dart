library flow.specs;

import 'package:sparkflow/sparkflow.dart';

void main(){
  
  var network = Network.create('example');

  network.infoStream.disconnect();
  
  var loop = Component.create('loop');
  loop.renamePort('in','suck');
  loop.renamePort('out','spill');
  loop.loopPorts('suck','spill');
  
  var costa = Component.create('costa');

  var cosmo = Component.create('cosmo');

  network.add(loop,'loopback');
  network.add(costa,'costa');
  network.add(cosmo,'cosmo');
  
  network.filter('cosmo').then((_){
    assert(_.data.UID == cosmo.UID);
  });
  
  //order goes component who wants to connect to component port with port
  network.connect('costa','loopback','in','out');

  network.freeze();
  //listen to info streams for update
  var buffer = new StringBuffer();
  network.infoStream.tap((n){
    buffer.write('-------------------\n');
    buffer.write('type: '+ n['type']);
    buffer.write('\n');
    buffer.write('message: '+ n['message']);
    buffer.write('\n');

    print('#Updates: \n${buffer.toString()}');
    buffer.clear();
  });

  network.boot();
}
