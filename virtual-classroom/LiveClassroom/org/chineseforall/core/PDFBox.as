package org.chineseforall.core
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.ui.Keyboard;
	
	import mx.controls.Alert;
	import mx.controls.SWFLoader;
	import mx.core.UIComponent;
	
	import org.chineseforall.components.PDFNav;
	
	import spark.components.HScrollBar;
	import spark.components.TextInput;
	import spark.components.VScrollBar;
	
	public class PDFBox
	{
		private var app:App = null;
		
		private var swfLoader:SWFLoader = null;
		private var url:String = null;
		private var canvas:UIComponent = null;
		private var rectView:Rectangle = null;
		private var PDFBodyMask:MovieClip = null;
		private var delta_y:uint = 0;
		private var original_body_width:uint = 0;
		private var original_body_height:uint = 0;
		private var vSBar:VScrollBar = null;
		private var vSBarValue:uint = 0;
		private var hSBar:HScrollBar = null;
		private var hSBarValue:uint = 0;
		private var dragMode:Boolean = false;
		private var pdfNav:PDFNav = null;
		private var pdfSwfMc:MovieClip = null;
		
		public function PDFBox(app_handle:App, pdf_url:String)
		{
			app = app_handle;
			url = pdf_url;
			
			// Setup the canvas
			canvas = new UIComponent();
			canvas.width = app.instance.whiteBoard.width;
			canvas.height = app.instance.whiteBoard.height;
			canvas.x = 5;
			canvas.y = 3;
			canvas.name = "zz1";
			app.instance.canvas.addChild(canvas);
			
			swfLoader = new SWFLoader();
			swfLoader.addEventListener(Event.COMPLETE, handlePDFLoaded);
			swfLoader.load(url);
		}
		
		private function reAdjustUI():void
		{
			pdfSwfMc.viewport.x = (canvas.width - pdfSwfMc.viewport.width)/2;
			pdfSwfMc.y = 41;
			
			//PDFBodyMask = new MovieClip();
			PDFBodyMask.y = 41;
			canvas.addChild(PDFBodyMask);
			PDFBodyMask.graphics.lineStyle();
			PDFBodyMask.graphics.beginFill(0xFFFFFF,1);
			PDFBodyMask.graphics.drawRect(0, 0, canvas.width - 29, canvas.height - 50);
			PDFBodyMask.graphics.endFill();
			pdfSwfMc.mask = PDFBodyMask;
			
			canvas.addChild(pdfSwfMc);
			
			//vSBar = new VScrollBar();
			vSBar.minimum = 0;
			vSBar.maximum = pdfSwfMc.viewport.height - canvas.height - 50 + 100;
			vSBar.y = 41;
			vSBar.x = canvas.width - 28;
			canvas.addChild(vSBar);
			vSBar.height = canvas.height - 50;
			
			//hSBar = new HScrollBar();
			hSBar.minimum = 0;
			hSBar.maximum = pdfSwfMc.viewport.width - canvas.width - 28 + 100;
			hSBar.y = canvas.height - 24;
			canvas.addChild(hSBar);
			hSBar.width = canvas.width - 28;
			canvas.setFocus();
		}
		
		private function handlePDFLoaded(e:Event):void{
			pdfSwfMc = swfLoader.content as MovieClip;
			
			// Let's setup the navigation bar
			pdfNav = new PDFNav();
			pdfNav.name = "nav";
			canvas.addChild(pdfNav);
			pdfNav.width = canvas.width - 12;
			pdfNav.txt_curPage.text = "1";
			pdfNav.lbl_numPages.text = pdfSwfMc.viewport.totalFrames.toString();
			
			pdfSwfMc.viewport.x = (canvas.width - pdfSwfMc.viewport.width)/2;
			pdfSwfMc.y = 41;
			
			PDFBodyMask = new MovieClip();
			PDFBodyMask.y = 41;
			canvas.addChild(PDFBodyMask);
			PDFBodyMask.graphics.lineStyle();
			PDFBodyMask.graphics.beginFill(0xFFFFFF,1);
			PDFBodyMask.graphics.drawRect(0, 0, canvas.width - 29, canvas.height - 50);
			PDFBodyMask.graphics.endFill();
			pdfSwfMc.mask = PDFBodyMask;
			
			canvas.addChild(pdfSwfMc);
			
			vSBar = new VScrollBar();
			vSBar.minimum = 0;
			vSBar.maximum = pdfSwfMc.viewport.height - canvas.height - 50 + 100;
			vSBar.y = 41;
			vSBar.x = canvas.width - 28;
			canvas.addChild(vSBar);
			vSBar.height = canvas.height - 50;
			
			hSBar = new HScrollBar();
			hSBar.minimum = 0;
			hSBar.maximum = pdfSwfMc.viewport.width - canvas.width - 28 + 100;
			hSBar.y = canvas.height - 24;
			canvas.addChild(hSBar);
			hSBar.width = canvas.width - 28;
			
			pdfNav.btn_nextPage.addEventListener(MouseEvent.CLICK, handlePDFNextPage);
			pdfNav.btn_prevPage.addEventListener(MouseEvent.CLICK, handlePDFPrevPage);
			pdfNav.btn_zoomIn.addEventListener(MouseEvent.CLICK, handlePDFZoomIn);
			pdfNav.btn_zoomOut.addEventListener(MouseEvent.CLICK, handlePDFZoomOut);
			pdfNav.txt_curPage.addEventListener(KeyboardEvent.KEY_UP, handlePDFChangePage);
			
			hSBar.addEventListener(Event.CHANGE, handlePDFBodyHScrollBar);
			vSBar.addEventListener(Event.CHANGE, handlePDFBodyVScrollBar);
			canvas.addEventListener(MouseEvent.MOUSE_WHEEL, handlePDFVScroll);
			
			// Click down/drag events
			pdfSwfMc.viewport.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			pdfSwfMc.viewport.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
			pdfSwfMc.viewport.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			pdfSwfMc.viewport.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
			canvas.setFocus();
			
		}
		
		private function handleMouseOut(e:MouseEvent):void
		{
			// Correct pdf position just in case
			handleMouseMove(e);
			pdfSwfMc.viewport.stopDrag();
			dragMode = false;
		}
		
		private function handleMouseMove(e:MouseEvent):void
		{
			var change:Number = 0;
			if(hSBar.maximum > 0) {
				if(dragMode && pdfSwfMc.viewport.x >= canvas.x) {
					pdfSwfMc.viewport.x = canvas.x;
				} else if(pdfSwfMc.viewport.x <= (canvas.width - pdfSwfMc.viewport.width - 40)) {
					pdfSwfMc.viewport.x = (canvas.width - pdfSwfMc.viewport.width - 40);
				}
				// Let's re-adjust the vertical scrollbar
				hSBar.value = Math.abs(pdfSwfMc.viewport.x - canvas.x);
				hSBarValue = hSBar.value;
			} else {
				if(dragMode)
					pdfSwfMc.viewport.x = (canvas.width - pdfSwfMc.viewport.width)/2;
			}
			if(dragMode && vSBar.maximum > 0) {
				if(pdfSwfMc.viewport.y <= (canvas.height - pdfSwfMc.height - 50)) {
					pdfSwfMc.viewport.y = (canvas.height - pdfSwfMc.height - 50);
				} else if(pdfSwfMc.viewport.y >= (canvas.y - 2)) {
					pdfSwfMc.viewport.y = (canvas.y - 2);
				}
				// Let's re-adjust the vertical scrollbar
				vSBar.value = Math.abs(pdfSwfMc.viewport.y);
				vSBarValue = vSBar.value;
			} else {
				if(dragMode)
					pdfSwfMc.viewport.y = canvas.y - 2;
			}
		}
		
		private function handleMouseDown(e:MouseEvent):void
		{
			pdfSwfMc.viewport.startDrag();
			dragMode = true;
		}
		
		private function handleMouseUp(e:MouseEvent):void
		{
			pdfSwfMc.viewport.stopDrag();
			dragMode = false;
		}
		
		private function handlePDFBodyHScrollBar(e:Event):void
		{
			var scrollbar:HScrollBar = e.currentTarget as HScrollBar;
			if(scrollbar.value < hSBarValue) {
				pdfSwfMc.viewport.x += hSBarValue - scrollbar.value;
			}
			else {
				pdfSwfMc.viewport.x -= scrollbar.value - hSBarValue;
			}
			hSBarValue = scrollbar.value;
		}
		
		private function handlePDFBodyVScrollBar(e:Event):void
		{
			var scrollbar:VScrollBar = e.currentTarget as VScrollBar;
			if(scrollbar.value < vSBarValue)
				pdfSwfMc.viewport.y += vSBarValue - scrollbar.value;
			else
				pdfSwfMc.viewport.y -= scrollbar.value - vSBarValue;
			vSBarValue = scrollbar.value;
		}
		
		private function handlePDFVScroll(e:MouseEvent):void
		{	
			var change:int = 0;
			if (e.delta > 0) {
				change = canvas.height - 50 + pdfSwfMc.viewport.y;
				if(change < (canvas.height - 50)) {
					if( canvas.height - 50 - change < 10) {
						vSBar.value -= canvas.height - 50 - change;
						pdfSwfMc.viewport.y += canvas.height - 50 - change;
					} else {
						vSBar.value -= 25;
						pdfSwfMc.viewport.y += 25;
					}
				}
			} else {
				change = canvas.height - 50 - pdfSwfMc.viewport.y;
				if(change < pdfSwfMc.viewport.height) {
					if(pdfSwfMc.height  - change < 10) {
						vSBar.value += pdfSwfMc.viewport.height - change;
						pdfSwfMc.viewport.y -= pdfSwfMc.viewport.height - change;
					} else {
						vSBar.value += 25;
						pdfSwfMc.viewport.y -= 25;
					}
				}
			}
		}
		
		private function handlePDFNextPage(e:MouseEvent):void
		{
			if(pdfSwfMc.viewport.currentFrame < pdfSwfMc.viewport.totalFrames) {
				pdfSwfMc.viewport.nextFrame();
				reAdjustUI();
				pdfSwfMc.viewport.y = 0;
				vSBar.value = 0;
				vSBarValue = 0;
				pdfNav.txt_curPage.text = pdfSwfMc.viewport.currentFrame.toString();
			}
		}
		private function handlePDFPrevPage(e:MouseEvent):void
		{
			if(pdfSwfMc.viewport.currentFrame > 0) {
				pdfSwfMc.viewport.prevFrame();
				reAdjustUI();
				pdfSwfMc.viewport.y = 0;
				vSBar.value = 0;
				vSBarValue = 0;
				pdfNav.txt_curPage.text = pdfSwfMc.viewport.currentFrame.toString();
			}
		}
		
		private function handlePDFChangePage(e:KeyboardEvent):void
		{
			var txt_curPage:TextInput = e.currentTarget as TextInput,
				value:uint = parseInt(txt_curPage.text);
			if(e.keyCode == Keyboard.ENTER && value > 0 && value <= pdfSwfMc.viewport.totalFrames) {
				pdfSwfMc.viewport.gotoAndStop(value);
				reAdjustUI();
				pdfSwfMc.viewport.y = 0;
				vSBar.value = 0;
				vSBarValue = 0;
			}
		}
		
		private function handlePDFZoomIn(e:MouseEvent):void
		{
			pdfSwfMc.viewport.scaleX += 0.12;
			pdfSwfMc.viewport.scaleY += 0.12;
			vSBar.maximum = pdfSwfMc.viewport.height - canvas.height + 50;
			pdfSwfMc.viewport.x = (canvas.width - pdfSwfMc.viewport.width)/2;
			if(pdfSwfMc.viewport.x < canvas.x) {
				hSBar.maximum = pdfSwfMc.viewport.width - canvas.width + 40;
				hSBar.value = Math.abs(pdfSwfMc.viewport.x - canvas.x);
				if(hSBar.value > 0) {
					hSBarValue = hSBar.value;
				}
			}
		}
		
		private function handlePDFZoomOut(e:MouseEvent):void
		{
			pdfSwfMc.viewport.scaleX -= 0.12;
			pdfSwfMc.viewport.scaleY -= 0.12;
			vSBar.maximum = pdfSwfMc.viewport.height - canvas.height + 50;
			pdfSwfMc.viewport.x = (canvas.width - pdfSwfMc.viewport.width)/2;
			hSBar.maximum = pdfSwfMc.viewport.width - canvas.width + 40;
			hSBar.value = Math.abs(pdfSwfMc.viewport.x - canvas.x);
			if(hSBar.value > 0) {
				hSBarValue = hSBar.value;
			} else {
				hSBarValue = 0;
			}
		}
		
		public function listenToFlash(stringToShow:String):void{
			Alert.show(stringToShow);
		}
		
	}
}