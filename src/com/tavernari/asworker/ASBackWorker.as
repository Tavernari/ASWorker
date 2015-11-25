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

	public class ASBackWorker
	{
		private var mainMessageChannel:MessageChannel;
		private var backMessageChannel:MessageChannel;
		private var backToMain:MessageChannel;
		
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
					
					NotificationCenter.setWorkerChannel( mainMessageChannel );
					
					_arr = controllers;
				}
				
			}else
			{
				_arr = controllers;
			}
		}
		
		protected function onMainToBack(event:Event):void
		{
			
			if(backMessageChannel.messageAvailable){
				const msg:* = backMessageChannel.receive(true);
				switch(msg)
				{
					case NotificationCenter.NOTIFICATION_MESSAGE:
					{
						const eventType:* = backMessageChannel.receive();
						const eventClassString:* = backMessageChannel.receive();
						const eventClass:Class = getDefinitionByName(eventClassString) as Class;
						
						var data:* = null;
						var dataClassString:String = backMessageChannel.receive();
						if(dataClassString)
						{
							const dataClass:Class = getDefinitionByName(dataClassString) as Class;
							dataClassString = dataClassString.indexOf("::") != -1 ? dataClassString.split("::")[1] : dataClassString;
							registerClassAlias(dataClassString, dataClass  );
							
							const ba:ByteArray = backMessageChannel.receive(true);
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