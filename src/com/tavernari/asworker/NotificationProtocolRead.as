package com.tavernari.asworker
{
	import com.tavernari.asworker.notification.NotificationCenterEvent;
	
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
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
			const data:* = dataClass == BitmapData ? getBitmpData(dataClass) : getData(dataClass);
			const event:NotificationCenterEvent = new eventClass( type );
			event.data = data;
			
			return event;
		}
		
		private function getBitmpData(dataClass:Class):*{
			const width:Number = byteArray.readFloat();
			const height:Number = byteArray.readFloat();
			const dataLenght:int = byteArray.readInt();
			
			const dataByteArray:ByteArray = new ByteArray();
			byteArray.readBytes(dataByteArray,0,dataLenght);
			
			const bmpData:BitmapData = new BitmapData(width, height);
			bmpData.setPixels( new Rectangle(width, height), dataByteArray );
			return bmpData;
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
			if(className.indexOf("::") != -1){
				var matches:Array = className.split("::");
				matches.shift();
				var eventClassString:String = matches.join("");
				registerClassAlias(eventClassString, eventClass);
			}else{
				registerClassAlias(className, eventClass);
			}
			return eventClass;
		}
	}
}