package com.tavernari.asworker
{
	import flash.display.Stage;
	import flash.system.Worker;

	public class ASWorker
	{
		private var uiWorker:ASUIWorker;
		private var backWorker:ASBackWorker;
		public function ASWorker(stage:Stage, uiStartWorkerCallBack:Function, backStartWorkerCallBack:Function)
		{
			if(Worker.isSupported)
			{
				if(Worker.current.isPrimordial)
				{
					uiWorker = new ASUIWorker(stage);
					uiStartWorkerCallBack();
				}else
				{
					backWorker = new ASBackWorker(stage);
					backStartWorkerCallBack();
				}
			}
		}
	}
}