<template>
</template>

<script>
//
if (process.browser) {
  var assert = require('assert');
  var Stats = require('stats.js');
  var _ = require('underscore');
  var ulib = require('ura1020-ulib');

  let log = ulib.log;

  function App(){
    let body = document.body;

    const SCREEN = {w:800,h:600};

    const BLOCK_SIZE = 32;
    const BLOCK_HORIZONTAL_NUM = 10;
    const BLOCK_VERTICAL_NUM = 20;
    const BLOCK_POSITION_GRID = {x:4,y:0};
    const BLOCK_EMPTY = 0;

    let renderer = new PIXI.autoDetectRenderer(SCREEN.w,SCREEN.h);
    let sceneScreen = new PIXI.Container();
    let sceneManager = SceneManager();

    let stats = new Stats();
    stats.setMode(0);

    body.append(renderer.view);
    body.append(stats.domElement);
    let render = () => {renderer.render(sceneScreen);}

    let canvasBase = CanvasBase();
    let canvasFront = CanvasFront();

    // function Resource(){
    //   onProgress = () => log("onProgress");
    //   onReady = () => log("onReady");

    //   this.load = function(paths){
    //     PIXI.loader
    //       .add(paths)
    //       .on("progress",onProgress)
    //       .load(onReady);
    //   }
    // }

    function SceneManager(){
      let scenes = [{ // 演出用と多重管理があり得る
        enter:() => {},
        exit:() => {},
        frame:() => {},
      }];

      let change = (scene) => {
        let _scene = scenes.shift();
        _scene.exit();
        scene.enter();
        scenes.push(scene);
      }

      function Fade(callback){
        // old scene +Fade enter
        // Fade(100%) old scene exit/new scene enter
        // Fade(0%) Fade exit
        const SIZE = SCREEN;
        const STATE_READY = 'READY';
        const STATE_IN = 'IN';
        const STATE_OUT = 'OUT';

        let view = new PIXI.Graphics();
        view.x = (SCREEN.w - SIZE.w) / 2;
        view.y = (SCREEN.h - SIZE.h) / 2;
        view.beginFill(0x000000);
        view.drawRect(0,0,SIZE.w,SIZE.h);
        view.endFill();

        let state = STATE_READY;
        let _scene = null;
        return {
          isReady:() => {return state == STATE_READY},
          enter:(scene) => {
            _scene = scene;
            view.alpha = 0.0;
            state = STATE_IN;
            canvasFront.addChild(view);
          },
          exit:() => {
            canvasFront.removeChild(view);
          },
          frame:() => {
            if(state == STATE_IN){
              view.alpha += 0.1;
              if(1.0 <= view.alpha){
                change(_scene);
                state = STATE_OUT
              }
            }
            if(state == STATE_OUT){
              view.alpha -= 0.1;
              if(view.alpha <= 0.0){
                callback(); // 演出終了なので掃除してもらう
                state = STATE_READY;
              }
            }
            render();
          },
          view:view,
        }
      }

      let fade = Fade(() => {scenes.shift();}); // 再利用可能
      return {
        fade:(scene) => {
          if(!fade.isReady()){ // 多重防止
            log("!fade.isReady()");
            return;
          }
          fade.enter(scene);
          scenes.push(fade);
        },
        change:change,
        frame:() => {
          for(let scene of scenes){
            scene.frame();
          }
        }
      }
    }

    function Result(){
      const SIZE = {w:SCREEN.w,h:240};
      let textView = null;

      let view = new PIXI.Graphics();
      let bg = new PIXI.Graphics();
      // bg.lineStyle(2,0x33FF00,1);
      bg.alpha = 0.5;
      bg.beginFill(0x000000);
      bg.drawRect(0,0,SCREEN.w,SCREEN.h);
      bg.endFill();
      view.addChild(bg);

      let base = new PIXI.Graphics();
      base.lineStyle(2,0x000000,1);
      base.beginFill(0xFFFFFF);
      base.drawRect(0,(SCREEN.h - SIZE.h) / 2,SIZE.w,SIZE.h);
      base.endFill();
      view.addChild(base)

      let labelView = new PIXI.Text("Score",{font:'bold 48pt Arial', fill:0x000000});
      labelView.position.x = 10;
      labelView.position.y = SCREEN.h / 2;
      labelView.anchor.x = 0;
      labelView.anchor.y = 0.5;
      view.addChild(labelView);

      let guideView = new PIXI.Text("Press space key to restart.",{font:'bold 24pt Arial', fill:0x000000});
      guideView.position.x = 10;
      guideView.position.y = SCREEN.h / 2 + 100;
      guideView.anchor.x = 0;
      guideView.anchor.y = 0.5;
      view.addChild(guideView);

      return {
        showResult:() => {
          textView = new PIXI.Text(score.scoreTotal(),{font:'bold 48pt Arial', fill:0x0000FF});
          textView.position.x = SIZE.w - 100;
          textView.position.y = SCREEN.h / 2;
          textView.anchor.x = 1;
          textView.anchor.y = 0.5;
          view.addChild(textView);
        },
        view:view,
      }
    }

    function CanvasBase(){
      const SIZE = SCREEN;

      let view = new PIXI.Graphics();
      view.x = (SCREEN.w - SIZE.w) / 2;
      view.y = (SCREEN.h - SIZE.h) / 2;
      view.beginFill(0xFFFFFF);
      view.drawRect(0,0,SIZE.w,SIZE.h);
      view.endFill();

      return {
        addChild:(child) => {
          view.addChild(child);
        },
        removeChild:(child) => {
          view.removeChild(child);
        },
        view:view,
      }
    }

    function CanvasFront(){
      const SIZE = SCREEN;

      let view = new PIXI.Graphics();
      view.x = (SCREEN.w - SIZE.w) / 2;
      view.y = (SCREEN.h - SIZE.h) / 2;

      return {
        addChild:(child) => {
          view.addChild(child);
        },
        removeChild:(child) => {
          view.removeChild(child);
        },
        view:view,
      }
    }

    function SceneGame(){
      const SIZE = {w:100,h:200};

      let view = new PIXI.Graphics();
      view.x = (SCREEN.w - SIZE.w) / 2;
      view.y = (SCREEN.h - SIZE.h) / 2;
      view.lineStyle(2,0x33FF00,1);
      view.beginFill(0xFF33FF);
      view.drawRect(0,0,SIZE.w,SIZE.h);
      view.endFill();

      let left = ulib.leftEvent();
      // let right = ulib.rightEvent();
      // let up = ulib.upEvent();
      // let down = ulib.downEvent();
      // let space = ulib.spaceEvent();

      return {
        enter:() => {
          left.press = () => {
            sceneManager.change(SceneGameResult());
          }
          canvasBase.addChild(view);
        },
        exit:() => {
          log("SceneGame.exit");
          left.removeEventAll();
          canvasBase.removeChild(view);
        },
        frame:() => {
          render();
        },
        view:view,
      }
    }

    function SceneGameResult(){
      const SIZE = {w:200,h:100};

      let view = new PIXI.Graphics();
      view.x = (SCREEN.w - SIZE.w) / 2;
      view.y = (SCREEN.h - SIZE.h) / 2;
      view.lineStyle(2,0x33FF00,1);
      view.beginFill(0x00FF00);
      view.drawRect(0,0,SIZE.w,SIZE.h);
      view.endFill();

      let space = ulib.spaceEvent();
      let up = ulib.upEvent();

      return {
        enter:() => {
          up.press = () => {
            // sceneManager.change(SceneGame());
            sceneManager.fade(SceneGame());
          }
          canvasBase.addChild(view);
        },
        exit:() => {
          log("SceneGameResult.exit");
          up.removeEventAll();
          space.removeEventAll();
          canvasBase.removeChild(view);
        },
        frame:() => {
          render();
        },
        view:view,
      }
    }

    let stage_num = "stage0001"

    // メインループ
    let mainLoop = function(window){
      // log("mainLoop")

      stats.begin();

      sceneManager.frame();

      stats.end();

      window.requestAnimationFrame(() => mainLoop(window));
    };

    // エントリポイント
    this.run = function(){

      sceneManager.change(SceneGame());
      // initSceneGame(stage_num);
      mainLoop(window);

      sceneScreen.addChild(canvasBase.view);
      sceneScreen.addChild(canvasFront.view);

      render();
    }
  }

  new App().run();
}


export default {
}
</script>
