package com.tavernari.asworker.notification
{
	import flash.concurrent.Mutex;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.registerClassAlias;
	import flash.system.MessageChannel;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	import avmplus.getQualifiedClassName;

	public class NotificationCenter
	{
		public static const MESSAGE_CHANNEL_UI:String = "mcui";
		public static const MESSAGE_CHANNEL_BACK:String = "mcb";
		public static const AS_WORK_INITIALIZED:String = "awi";
		public static const NOTIFICATION_MESSAGE:String = "nm";
		
		public static const BOTH:int = 0;
		public static const NATIVE_EVENT_DISPATCHER:int = 1;
		public static const ASWORK_EVENT:int = 2;
		
		private static const eventDispatcher:EventDispatcher = new EventDispatcher();
		private static var _baSpeaker:ByteArray;
		private static var _channel:MessageChannel;
		private static var _mutex:Mutex;
		private static var _channelQueue:Vector.<NotificationCenterEvent> = new Vector.<NotificationCenterEvent>();
		
		public static function setByteArrayInfo(wokerchannel:ByteArray):void
		{
			_baSpeaker = wokerchannel;
		}
		
		public static function setChanngel(wokerchannel:MessageChannel):void
		{
			_channel = wokerchannel;
		}
		
		public static function setMutex(mutex:Mutex):void
		{
			_mutex = mutex;
		}
		
		public static function addEventListener(type:String,listener:Function,priority:int = 0,weakReference:Boolean = true):void
		{
			eventDispatcher.addEventListener(type,listener,false,priority,weakReference);
		}
		
		private static var eventQueue:Vector.<NotificationCenterEvent> = new Vector.<NotificationCenterEvent>();
		private static var lock:Boolean = false;
		private static var bufferSize:int = 500000;
		
		public static function dispatchEvent(event:NotificationCenterEvent, sendWith:int = BOTH):void
		{
			if(_baSpeaker && (sendWith == BOTH || sendWith == ASWORK_EVENT) && _channelQueue.length == 0 && _baSpeaker != null && (event.sendBy == BOTH || event.sendBy == ASWORK_EVENT))
			{
				if (_mutex.tryLock()){
					
				eventQueue.push(event);
				lock = true;
				
				const tempBA:ByteArray = new ByteArray();
				
				if(_baSpeaker.length < _baSpeaker.position){
					_baSpeaker.position = _baSpeaker.length;
				}
				
				while(_baSpeaker.length < bufferSize){
					
					tempBA.clear();
					
					const queueEvent:NotificationCenterEvent = eventQueue.shift();
					
					if(queueEvent == null){
						_mutex.unlock();
						return;
					}

					var type:String = queueEvent.type;
					var evtClass:String = getQualifiedClassName(queueEvent);
					
					_baSpeaker.writeInt(evtClass.length);
					_baSpeaker.writeUTFBytes(evtClass);
					
					_baSpeaker.writeInt(type.length);
					_baSpeaker.writeUTFBytes(type);
					
					const objectClass:String = getQualifiedClassName(queueEvent.data);
					
					if(objectClass.indexOf("::") != -1)
						registerClassAlias(objectClass.split("::")[1], getDefinitionByName(objectClass) as Class );
					else
						registerClassAlias(objectClass, getDefinitionByName(objectClass) as Class );
					
					_baSpeaker.writeInt(objectClass.length);
					_baSpeaker.writeUTFBytes(objectClass);
					
					tempBA.writeObject( queueEvent.data );
					_baSpeaker.writeInt( tempBA.length );
					_baSpeaker.writeObject( queueEvent.data );
				}
									
				_mutex.unlock();
				
				}else{
					eventQueue.push( event );
				}
				
				//_channel.send(msg, event.data ? 3 : 1);
				//_channel.send(type );
				//_channel.send(evtClass);
				
				/*if(event.data)
				{
					const objectClass:String = getQualifiedClassName(event.data);
					_channel.send( objectClass );
					
					if(objectClass.indexOf("::") != -1)
						registerClassAlias(objectClass.split("::")[1], getDefinitionByName(objectClass) as Class );
					else
						registerClassAlias(objectClass, getDefinitionByName(objectClass) as Class );

					const byteArray:ByteArray = new ByteArray();
					byteArray.position = 0;
					byteArray.writeObject( event.data );
					byteArray.position = 0;
					
					_channel.send(byteArray);
				}*/
			}
			
			if( eventDispatcher.hasEventListener( event.type ) )
			{
				eventDispatcher.dispatchEvent( event );
			}
		}
		
		public static function getEventDispatcher():EventDispatcher
		{
			return eventDispatcher;
		}
	}
}