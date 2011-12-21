/*

You just couldnt resist, could you. I slapped this together pretty quickly to get it functional, 
and then started piling on features so dont judge!
I plan to go back into it and clean things up at some point.

*/

package com.benatwork
{
	import com.adobe.serialization.json.JSON;
	import com.benatwork.Player;
	import com.benatwork.PlayerEvent;
	import com.greensock.TweenLite;
	import com.radioclouds.visualizer.models.Comment;
	import com.radioclouds.visualizer.models.Track;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	

	public class Main extends Sprite
	{
		private var userID:String = "benatwork12";
		private var trackIdArray:Array = ["30719240","30719552","30719988","30720143","30720450"];
		private var secretTokenArray:Array = ["s-zsvBu","s-l9cge","s-UO5WL","s-a0tQ5","s-e1CzB"];
		private var clipTitles:Array = ["Intro", "Future", "Past","Outro", "10 Facts"];
		private var API_KEY:String = "d2e9027079da528682ce6fb2735a6b62";
		private var _sound:Sound;
		private var _soundChannel : SoundChannel;
		private var _isPaused:Boolean = true;
		private var _seekPosition:Number;
		private var _soundDuration:Number;
		private var _defaultVolume:Number = .8;
		private var _currentVolume:Number = _defaultVolume;
		private var _bufferProgress:MovieClip;
		private var comments:Array = new Array();
		private var player:Player
		private var isFinished:Boolean = false;
		private var selectors:Array = new Array();
		
		private var currentTrackId:uint;
		private var track:Track;
		
		public function Main()
		{
			player = new Player();
			player.x = 47;
			player.y = 74;
			player.alpha = 0;
			addChild(player);			
			
			initTrack(0);
			
		}
		private function setupSelectors(titles:Array){
			var totalWidth:Number = 0;
			for (var i in clipTitles){
				var sel:Selector = new Selector(i,clipTitles[i]);
				addChild(sel);
				sel.x = player.x+20 + totalWidth;
				sel.y = player.y-20;
				selectors.push(sel);
				totalWidth += sel.actualWidth;
				sel.addEventListener(PlayerEvent.TRACK_SELECTED, onTrackChange);
			}
		}
		private function onTrackChange(e:PlayerEvent = null){
			player._console.text = "Connecting to soundcloud..."
			_soundChannel.stop();
			_sound.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			_sound.removeEventListener(ProgressEvent.PROGRESS, soundLoading);
			_soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			e ? initTrack((e.currentTarget as Selector).id) : initTrack(currentTrackId + 1);
		}
		private function initTrack(trackId:uint){
			currentTrackId = trackId;
			getTracks(trackId);
			
		}
		private function toggleTrackTabs(trackId){
			for (var i in selectors){
				//i == trackId ? selectors[i].activate() : selectors[i].deactivate();
				if(i== trackId){
					selectors[i].activate();
				} else {
					selectors[i].deactivate();
				}
			}
		}
		private function getTracks(trackId:uint){
			player._console.text = "Connecting to soundcloud..."
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest("https://api.soundcloud.com/tracks/"+trackIdArray[trackId]+".json?client_id="+API_KEY+"&secret_token="+secretTokenArray[trackId]);
			loader.addEventListener(Event.COMPLETE, onTracksLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, tracksError);
			loader.load(request);
		}
		private function getComments(trackId:uint){
			player._console.text = "Loading comments..."
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest("https://api.soundcloud.com/tracks/"+trackIdArray[trackId]+"/comments.json?client_id="+API_KEY+"&secret_token="+secretTokenArray[trackId]);
			loader.addEventListener(Event.COMPLETE, onCommentsLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, commentsError);
			loader.load(request);
		}
		private function commentsError(e:IOErrorEvent){
			player._console.text = 'Error getting comments, retrying...';
			getTracks(getComments(currentTrackId));
		}
		private function tracksError(e:IOErrorEvent){
			player._console.text = 'Error getting the sound clip data, retrying...';
			getTracks(currentTrackId);
		}
		

		private function onTracksLoaded(e:Event):void {  
			e.target.removeEventListener(Event.COMPLETE, onTracksLoaded);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, tracksError);
			var loader:URLLoader = URLLoader(e.target);
			var jsonData:Object = JSON.decode(loader.data);
	
			track = new Track(jsonData);
			getComments(currentTrackId);
			if( selectors.length < 1) setupSelectors(clipTitles);
			toggleTrackTabs(currentTrackId)
			TweenLite.to(player, .5, {alpha:1});
			
			setChildIndex(player,numChildren - 1)
			playTrack(track);
			
		}
		private function onCommentsLoaded(e:Event){
			e.target.removeEventListener(Event.COMPLETE, onCommentsLoaded);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, commentsError);
			var loader:URLLoader = URLLoader(e.target);
			var jsonData:Array = JSON.decode(loader.data);
			
			for each (var i in jsonData){
				var comment = new Comment(i);
				comments.push(comment);
				player.createComment(comment);
			} 
			
		}
		
		private function playTrack(track : Track) : void {
			var url : String = track.streamUrl;
			
			player.initPlayer(track);
			player.addEventListener(PlayerEvent.VOLUME_CHANGED,changeSoundVolume);
			player.addEventListener(PlayerEvent.SEEK, onSeek);
			player.addEventListener(PlayerEvent.PLAYTOGGLE, playToggle);
			
			 _soundDuration = track.duration;
			_seekPosition = 0;
			
			_sound = new Sound();
			_sound.load(new URLRequest(tokenizeUrl(url)));
			_sound.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			_sound.addEventListener(ProgressEvent.PROGRESS, soundLoading);
			_soundChannel = _sound.play(_seekPosition);
			changeSoundVolume();
			player.changeSoundVolume(_defaultVolume);

			_soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			
			removeEventListener(Event.ENTER_FRAME, onUpdate);
			addEventListener(Event.ENTER_FRAME, onUpdate);
			player._console.text = ""
			player.paused = _isPaused;
			if(_isPaused) stopSound();
		}
		private function onLoadError(event : IOErrorEvent) : void {
			player._console.text = 'Error getting the sound clip, retrying...';
			playTrack(track);
		}
		private function soundLoading(e:ProgressEvent){
			var value:Number = e.bytesLoaded/e.bytesTotal;
			player.updateBuffer(value);
			
			
		}
		public function playToggle(e:PlayerEvent = null):void {
			if(isFinished) {
				player.seekPosition = 0;
				_isPaused = false
				player.paused = false;
				isFinished = false;
				player.dispatchEvent(new PlayerEvent(PlayerEvent.SEEK));
				
			} else {
				if(_isPaused){
					resumeSound();
				}else{
					stopSound();	
				}
			}
		}
		
		public function stopSound():void {
			if(_soundChannel) {
				_seekPosition = _soundChannel.position;
				_soundChannel.stop();
			}else {
				_seekPosition = 0;	
			}
			_isPaused = true;
			player.paused = _isPaused;
		}
		public function resumeSound():void {
			if(_soundChannel) {
				_soundChannel.stop();
				_soundChannel = _sound.play(_seekPosition);	
				changeSoundVolume();
				_soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
			}
			isFinished = false;
			_isPaused = false;
			player.paused = _isPaused;
		}
		private function changeSoundVolume(e:PlayerEvent = null) : void {
			var nv:Number = e ? player.getVolume() : _defaultVolume ;
			var transform:SoundTransform = new SoundTransform();
			transform.volume = nv;
			_defaultVolume = nv;	
			_soundChannel.soundTransform = transform;
			
		}
	
		private function onSoundComplete(e:Event){
			isFinished = true;
			stopSound();
			resumeSound();
			trace(currentTrackId, trackIdArray.length);
			currentTrackId+1 < trackIdArray.length ? onTrackChange() : stopSound();
			
		}
		
		private function onSeek(e:Event = null){
			_soundChannel.stop();
			_soundChannel = _sound.play(player.seekPosition);
			_seekPosition = player.seekPosition;
			_isPaused = false;
			changeSoundVolume()
			resumeSound();
		
		}
		
		private function onUpdate(e:Event){
			player.updateSeek(_soundChannel.position);
		}
		
		public function tokenizeUrl(url : String) : String {
			return url + (/\?/.test(url) ? "&" : "?") + "oauth_consumer_key=" + API_KEY;
		}
		
	
	}
}