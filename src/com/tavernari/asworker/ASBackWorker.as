package com.tavernari.asworker
{
	import com.tavernari.asworker.notification.NotificationCenter;
	import com.tavernari.asworker.notification.NotificationCenterEvent;
	
	import flash.concurrent.Condition;
	import flash.concurrent.Mutex;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.net.registerClassAlias;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;

	public class ASBackWorker
	{
		private var mainMessageChannel:MessageChannel;
		private var backMessageChannel:MessageChannel;
		private var backToMain:MessageChannel;
		
		private var backSpeakerBA:ByteArray;
		private var uiSpeakerBA:ByteArray;
		private var backMutex:Mutex;
		private var uiMutex:Mutex;
		
		private var _arr:Array;
		
		public function ASBackWorker(stage:Stage, ...controllers)
		{
			if(Worker.isSupported )
			{
				if(Worker.current.isPrimordial == false)
				{
					var worker:Worker;
					
					if(!Worker.current)
					{
						worker = WorkerDomain.current.createWorker(new ByteArray(), true)
					}else
					{
						worker = Worker.current;
					}
					
					mainMessageChannel = Worker.current.getSharedProperty(NotificationCenter.MESSAGE_CHANNEL_UI);
					backMessageChannel = Worker.current.getSharedProperty(NotificationCenter.MESSAGE_CHANNEL_BACK);
					backMessageChannel.addEventListener(Event.CHANNEL_MESSAGE, onMainToBack);

					_arr = controllers;
					
					backSpeakerBA = new ByteArray();
					backSpeakerBA.shareable = true;
					NotificationCenter.setChanngel( mainMessageChannel );
					
					backMutex = new Mutex();
					worker.setSharedProperty("backMutex", backMutex);
					worker.setSharedProperty("backSpeakerBA", backSpeakerBA);
					
					do
					{
						uiSpeakerBA = worker.getSharedProperty("uiSpeakerBA") as ByteArray;
					}
					while (uiSpeakerBA == null);
					
					do
					{
						uiMutex = worker.getSharedProperty("uiMutex") as Mutex;
					}
					while (uiMutex == null);
					
					NotificationCenter.setMutex( backMutex );
					NotificationCenter.setByteArrayInfo( backSpeakerBA );
					
				}
				
			}else
			{
				_arr = controllers;
			}
		}
		
		protected function read():void
		{
			if(uiSpeakerBA.bytesAvailable > 0){
				uiSpeakerBA.position = 0;
				var textSize:int = uiSpeakerBA.readInt();
				var className:String = uiSpeakerBA.readUTFBytes(textSize);
				var obj:* = uiSpeakerBA.readObject();
				uiSpeakerBA.clear();
				
			}
		}	
		
		protected function onMainToBack(event:Event):void
		{
			
			if(backMessageChannel.messageAvailable){
				var msg:* = backMessageChannel.receive(true);
				switch(msg)
				{
					case NotificationCenter.NOTIFICATION_MESSAGE:
					{
						var eventType:* = backMessageChannel.receive();
						var eventClassString:* = backMessageChannel.receive();
						if(eventClassString == null){
							trace("eventClassString is nulllll");
							return;
						}
						var eventClass:Class = getDefinitionByName(eventClassString) as Class;
						
						var data:* = null;
						var dataClassString:String = backMessageChannel.receive();
						if(dataClassString)
						{
							var dataClass:Class = getDefinitionByName(dataClassString) as Class;
							dataClassString = dataClassString.indexOf("::") != -1 ? dataClassString.split("::")[1] : dataClassString;
							registerClassAlias(dataClassString, dataClass  );
							
							var ba:ByteArray = backMessageChannel.receive(true);
							ba.position = 0;
							data = ba.readObject() as dataClass;
						}

						var reEvent:NotificationCenterEvent = new eventClass( eventType );
						reEvent.data = data;
						NotificationCenter.dispatchEvent(reEvent, NotificationCenter.NATIVE_EVENT_DISPATCHER );
						
						break;
					}
						
					default:
					{
						break;
					}
				}
			}
			
		}
	}
}