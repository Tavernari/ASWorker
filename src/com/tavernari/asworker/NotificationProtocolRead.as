package com.tavernari.asworker
{
	import com.tavernari.asworker.notification.NotificationCenterEvent;
	
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;

	internal class NotificationProtocolRead
	{
		private var byteArray:ByteArray;
		
		public function NotificationProtocolRead(byteArray:ByteArray)
		{
			this.byteArray = byteArray;
		}
		
		public function read():NotificationCenterEvent{
			
			const eventClassName:String = getNextStringFromBA();
			
			if(eventClassName == null || eventClassName == ""){
				return null;
			}
			
			const eventClass:Class = registerClass( eventClassName );
			const type:String = getNextStringFromBA();
			const dataClassName:String = getNextStringFromBA();
			const dataClass:Class = registerClass(dataClassName);
			const data:* = getData(dataClass);
			const event:NotificationCenterEvent = new eventClass( type );
			event.data = data;
			
			return event;
		}
		
		private function getData(dataClass:Class):*{
			const dataLenght:int = byteArray.readInt();
			
			const dataByteArray:ByteArray = new ByteArray();
			byteArray.readBytes(dataByteArray,0,dataLenght);
			return dataClass(dataByteArray.readObject())
		}
		
		private function getNextStringFromBA():String{
			const textSize:int = byteArray.readInt();
			return byteArray.readUTFBytes(textSize);
		}
		
		private function registerClass(className:String):Class{
			const eventClass:Class = getDefinitionByName(className) as Class;
			const eventClassString:String = className.indexOf("::") != -1 ? className.split("::")[1] : className;
			registerClassAlias(eventClassString, eventClass);
			return eventClass;
		}
	}
}