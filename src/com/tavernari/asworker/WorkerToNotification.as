package com.tavernari.asworker
{
	import com.tavernari.asworker.notification.NotificationCenter;
	import com.tavernari.asworker.notification.NotificationCenterEvent;
	
	import flash.concurrent.Mutex;
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.utils.ByteArray;

	internal class WorkerToNotification
	{
		private var byteArraySpeaker:ByteArray;
		private var mutex:Mutex;
		private var messageChannel:MessageChannel;
		
		public function WorkerToNotification(byteArraySpeaker:ByteArray, mutex:Mutex, messageChannel:MessageChannel)
		{
			this.byteArraySpeaker = byteArraySpeaker;
			this.mutex = mutex;
			this.messageChannel = messageChannel;
			this.messageChannel.addEventListener(Event.CHANNEL_MESSAGE, onMessageChannelHandler,false,0,true);
		}
		
		protected function onMessageChannelHandler(e:Event):void
		{
			if(messageChannel.messageAvailable){
				const msg:* = messageChannel.receive(true);
				if(msg == "rd")
				{
					notify();
				}
			}	
		}
		
		private function notify():void
		{
			if(mutex.tryLock()){
			byteArraySpeaker.position = 0;
			while(byteArraySpeaker.bytesAvailable > 0){
				const event:NotificationCenterEvent = new NotificationProtocolRead(byteArraySpeaker).read();
				
				if(event == null){
					resetByteArrayAndUnlock();
					return;
				}
				
				sendNotification(event);
			}
			
			resetByteArrayAndUnlock();
			
			}
		}
		
		private function sendNotification(event:NotificationCenterEvent):void{
			NotificationCenter.dispatchEvent(event);
		}
		
		private function resetByteArrayAndUnlock():void{
			byteArraySpeaker.clear();
			byteArraySpeaker.position = 0;
			mutex.unlock();
		}
		
		
	}
}