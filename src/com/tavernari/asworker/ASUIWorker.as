package com.tavernari.asworker
{
	import com.taverna.capuchin.PhysisEvent;
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

	public class ASUIWorker
	{
		private var mainMessageChannel:MessageChannel;
		private var backMessageChannel:MessageChannel;
		private var worker:Worker;
		
		private var _arr:Array;
		
		private var backSpeakerBA:ByteArray;
		private var uiSpeakerBA:ByteArray;
		private var uiMutex:Mutex;
		private var backMutex:Mutex;
		
		public function ASUIWorker(stage:Stage, ...controllers)
		{
			if(Worker.isSupported)
			{
				if(Worker.current.isPrimordial)
				{
					worker = WorkerDomain.current.createWorker(stage.loaderInfo.bytes, true);
					
					mainMessageChannel = worker.createMessageChannel(Worker.current);
					mainMessageChannel.addEventListener(Event.CHANNEL_MESSAGE, onMainReceiveMessageHandler);
					
					backMessageChannel = Worker.current.createMessageChannel(worker);	
					NotificationCenter.setChanngel( backMessageChannel );
					
					worker.setSharedProperty(NotificationCenter.MESSAGE_CHANNEL_UI, mainMessageChannel);
					worker.setSharedProperty(NotificationCenter.MESSAGE_CHANNEL_BACK, backMessageChannel);
					
					worker.start();
					
					_arr = controllers;
					
					uiSpeakerBA = new ByteArray();
					uiSpeakerBA.shareable = true;
					
					uiMutex = new Mutex();
					worker.setSharedProperty("uiMutex", uiMutex);
					worker.setSharedProperty("uiSpeakerBA", uiSpeakerBA);
					
					do
					{
						backSpeakerBA = worker.getSharedProperty("backSpeakerBA") as ByteArray;
					}
					while (backSpeakerBA == null);
					
					do
					{
						backMutex = worker.getSharedProperty("backMutex") as Mutex;
					}
					while (backMutex == null);
					
					NotificationCenter.setMutex(uiMutex);
					NotificationCenter.setByteArrayInfo( uiSpeakerBA );
					
					stage.addEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
				}
			}else
			{
				_arr = controllers;
			}
		}

		protected function onEnterFrameHandler(event:Event):void
		{
			read();
		}
		
		protected function read():void
		{
				if(backMutex.tryLock()){
					backSpeakerBA.position = 0;
						while(backSpeakerBA.bytesAvailable > 0){
							var eventClassName:String = getNextStringFromBA();
							if(eventClassName == null || eventClassName == ""){
								backMutex.unlock();
								backSpeakerBA.position = 0;
								backSpeakerBA.clear();
								return;
							}
							var eventClass:Class = registerClass( eventClassName );
							
							var type:String = getNextStringFromBA();
							
							var dataClassName:String = getNextStringFromBA();
							var dataClass:Class = registerClass(dataClassName);
							
							var dataLenght:int = backSpeakerBA.readInt();
							
							var dataByteArray:ByteArray = new ByteArray();
							backSpeakerBA.readBytes(dataByteArray,0,dataLenght);
							var data:* = dataClass(dataByteArray.readObject())
							
							var reEvent:NotificationCenterEvent = new eventClass( type );
							reEvent.data = data;
							NotificationCenter.dispatchEvent(reEvent, NotificationCenter.NATIVE_EVENT_DISPATCHER );
						}
						
						backSpeakerBA.clear();
						backSpeakerBA.position = 0;
						
						
						backMutex.unlock();
					}

				function getNextStringFromBA():String{
					var textSize:int = backSpeakerBA.readInt();
					return backSpeakerBA.readUTFBytes(textSize);
				}
				
				function registerClass(className:String):Class{
					var eventClass:Class = getDefinitionByName(className) as Class;
					var eventClassString:String = className.indexOf("::") != -1 ? className.split("::")[1] : className;
					registerClassAlias(eventClassString, eventClass);
					return eventClass;
				}
		}		
		
		protected function onMainReceiveMessageHandler(e:Event):void
		{
			if(mainMessageChannel.messageAvailable){
				var msg:* = mainMessageChannel.receive(true);
				
				switch(msg)
				{
					case "read":
					{
						read();
						
						break;
					}
					
					case NotificationCenter.NOTIFICATION_MESSAGE:
					{
						var eventType:* = mainMessageChannel.receive();
						var eventClassString:* = mainMessageChannel.receive();
						var eventClass:Class = getDefinitionByName(eventClassString) as Class;
						var data:* = null;
						var dataClassString:String = mainMessageChannel.receive();
						if(dataClassString)
						{
							var dataClass:Class = getDefinitionByName(dataClassString) as Class;
							dataClassString = dataClassString.indexOf("::") != -1 ? dataClassString.split("::")[1] : dataClassString;
							registerClassAlias(dataClassString, dataClass );
							
							var ba:ByteArray = mainMessageChannel.receive(true);
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