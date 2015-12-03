package com.tavernari.asworker.notification
{
	
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	import avmplus.getQualifiedClassName;

	internal class NotificationProtocolWrite
	{
		private var byteArray:ByteArray;
		private var event:NotificationCenterEvent;
		public function NotificationProtocolWrite(byteArray:ByteArray)
		{
			this.byteArray = byteArray;
		}
		
		public function configEventClass(event:NotificationCenterEvent):NotificationProtocolWrite{
			this.event = event;
			return this;
		}
		
		public function write():void{
			writeEventClass();
			writeEventType();
			wirteData();
		}
		
		private function registerClass(className:String):Class{
			const eventClass:Class = getDefinitionByName(className) as Class;
			if(className.indexOf("::") != -1){
				const matches:Array = className.split("::");
				matches.shift();
				const eventClassString:String = matches.join("");
				registerClassAlias(eventClassString, eventClass);
			}else{
				registerClassAlias(className, eventClass);
			}
			return eventClass;
		}
		
		private function wirteData():void
		{
			const tempBA:ByteArray = new ByteArray();
			
			const objectClass:String = getQualifiedClassName(event.data);
			registerClass(objectClass)
			byteArray.writeInt(objectClass.length);
			byteArray.writeUTFBytes(objectClass);
			
			if(event.data is BitmapData){
				
				const bmpData:BitmapData = BitmapData(event.data);
				byteArray.writeFloat(bmpData.width);
				byteArray.writeFloat(bmpData.height);
				const bmpDataBA:ByteArray = bmpData.getPixels(new Rectangle(0,0,bmpData.width, bmpData.height) ) 
				byteArray.writeInt( bmpDataBA.length );
				byteArray.writeBytes( bmpDataBA );
				
			}else{
				tempBA.writeObject( event.data );
				byteArray.writeInt( tempBA.length );
				byteArray.writeBytes( tempBA );
			}
		}
		
		private function writeEventType():void
		{
			byteArray.writeInt(event.type.length);
			byteArray.writeUTFBytes(event.type);
		}
		
		private function writeEventClass():void{
			const evtClass:String = getQualifiedClassName(event);
			
			byteArray.writeInt(evtClass.length);
			byteArray.writeUTFBytes(evtClass);
		}
		
	}
}