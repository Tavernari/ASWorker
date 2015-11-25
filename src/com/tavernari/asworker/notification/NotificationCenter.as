package com.tavernari.asworker.notification
{
	import flash.events.EventDispatcher;
	import flash.net.registerClassAlias;
	import flash.system.MessageChannel;
	import flash.system.MessageChannelState;
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
		private static var _channel:MessageChannel;
		private static var _channelQueue:Vector.<NotificationCenterEvent> = new Vector.<NotificationCenterEvent>();
		
		public static function setWorkerChannel(wokerchannel:MessageChannel):void
		{
			_channel = wokerchannel;
		}
		
		public static function addEventListener(type:String,listener:Function,priority:int = 0,weakReference:Boolean = true):void
		{
			eventDispatcher.addEventListener(type,listener,false,priority,weakReference);
		}
		
		public static function dispatchEvent(event:NotificationCenterEvent, sendWith:int = BOTH):void
		{
			if(_channel && (sendWith == BOTH || sendWith == ASWORK_EVENT) && _channelQueue.length == 0 && _channel.state == MessageChannelState.OPEN && (event.sendBy == BOTH || event.sendBy == ASWORK_EVENT))
			{
				const msg:String = NOTIFICATION_MESSAGE;
				const type:String = event.type;
				const evtClass:String = getQualifiedClassName(event);
				
				_channel.send(msg, event.data ? 3 : 1);
				_channel.send(type );
				_channel.send(evtClass);
				
				if(event.data)
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
				}
			}
			
			if( eventDispatcher.hasEventListener( event.type ) &&
				(sendWith == BOTH || sendWith == NATIVE_EVENT_DISPATCHER) &&
				(event.sendBy == BOTH || event.sendBy == NATIVE_EVENT_DISPATCHER))
			{
				eventDispatcher.dispatchEvent( event );
			}
		}
		
		public static function getEventDispatcher():EventDispatcher
		{
			return eventDispatcher;
		}
		
		public static function getWorkerMessageChannel():MessageChannel
		{
			return _channel
		}
	}
}