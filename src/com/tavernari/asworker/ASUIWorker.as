package com.tavernari.asworker
{
	import com.tavernari.asworker.notification.NotificationCenter;
	import com.tavernari.asworker.notification.NotificationCenterEvent;
	
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
					NotificationCenter.setWorkerChannel(backMessageChannel);
					
					worker.setSharedProperty(NotificationCenter.MESSAGE_CHANNEL_UI, mainMessageChannel);
					worker.setSharedProperty(NotificationCenter.MESSAGE_CHANNEL_BACK, backMessageChannel);
					
					worker.start();
					
					_arr = controllers;
				}
			}else
			{
				_arr = controllers;
			}
		}
		
		protected function onMainReceiveMessageHandler(e:Event):void
		{
			if(mainMessageChannel.messageAvailable){
				const msg:* = mainMessageChannel.receive(true);
				
				switch(msg)
				{
					case NotificationCenter.NOTIFICATION_MESSAGE:
					{
						const eventType:* = mainMessageChannel.receive();
						const eventClassString:* = mainMessageChannel.receive();
						const eventClass:Class = getDefinitionByName(eventClassString) as Class;
						var data:* = null;
						var dataClassString:String = mainMessageChannel.receive();
						if(dataClassString)
						{
							const dataClass:Class = getDefinitionByName(dataClassString) as Class;
							dataClassString = dataClassString.indexOf("::") != -1 ? dataClassString.split("::")[1] : dataClassString;
							registerClassAlias(dataClassString, dataClass );
							
							const ba:ByteArray = mainMessageChannel.receive(true);
							ba.position = 0;
							data = ba.readObject() as dataClass;
						}
						
						const reEvent:NotificationCenterEvent = new eventClass( eventType );
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