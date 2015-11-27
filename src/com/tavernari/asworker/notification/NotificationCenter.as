package com.tavernari.asworker.notification
{
	import flash.concurrent.Mutex;
	import flash.events.EventDispatcher;
	import flash.system.MessageChannel;
	import flash.utils.ByteArray;

	public class NotificationCenter
	{		
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
		
		public static function dispatchEventBetweenWorkers(event:NotificationCenterEvent):void{
			if(_baSpeaker)
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
							break;
						}
						
						new NotificationProtocolWrite(_baSpeaker)
						.configEventClass(queueEvent)
							.write();
					}
					
					_mutex.unlock();
					_channel.send("rd");
					
				}else{
					eventQueue.push( event );
				}
			}
		}
		
		public static function dispatchEvent(event:NotificationCenterEvent):void
		{
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