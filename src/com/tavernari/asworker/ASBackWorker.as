package com.tavernari.asworker
{
	import com.tavernari.asworker.notification.NotificationCenter;
	
	import flash.concurrent.Mutex;
	import flash.display.Stage;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;

	internal class ASBackWorker
	{
		public static const MESSAGE_CHANNEL_BACK:String = "asw_mcb";
		
		private var mainMessageChannel:MessageChannel;
		private var backMessageChannel:MessageChannel;
		private var backToMain:MessageChannel;
		
		private var backSpeakerBA:ByteArray;
		private var uiSpeakerBA:ByteArray;
		private var backMutex:Mutex;
		private var uiMutex:Mutex;
		
		private var workerToNotification:WorkerToNotification;
		
		public function ASBackWorker(stage:Stage)
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
					
					mainMessageChannel = Worker.current.getSharedProperty(ASUIWorker.MESSAGE_CHANNEL_UI);
					backMessageChannel = Worker.current.getSharedProperty(MESSAGE_CHANNEL_BACK);

					backSpeakerBA = new ByteArray();
					backSpeakerBA.shareable = true;
					
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
					
					workerToNotification = new WorkerToNotification(uiSpeakerBA, uiMutex, backMessageChannel);
					
					NotificationCenter.setChanngel( mainMessageChannel );
					NotificationCenter.setMutex( backMutex );
					NotificationCenter.setByteArrayInfo( backSpeakerBA );
				}		
			}
		}
	}
}