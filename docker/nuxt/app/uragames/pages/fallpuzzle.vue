<template>
</template>

<script>
if (process.browser) {
  // クライアントレンダリング
  var Stats = require('stats.js');
  var _ = require('underscore');
  var ulib = require('ura1020-ulib');

  let log = ulib.log;
  let keyboard = ulib.keyboard;

  function App(){
    const SCREEN = {w:640,h:640};

    const BLOCK_SIZE = 32;
    const BLOCK_HORIZONTAL_NUM = 10;
    const BLOCK_VERTICAL_NUM = 20;
    const BLOCK_POSITION_GRID = {x:4,y:0};
    const BLOCK_EMPTY = 0;

    let renderer = new PIXI.autoDetectRenderer(SCREEN.w,SCREEN.h);
    let blockFactory = new BlockFactory();
    let player = Player();
    let sceneScreen = new PIXI.Container(); // シーン用ステージにしよう
    let outline = Outline();
    let next = Next();
    let level = Level();
    let score = Score();

    renderer.backgroundColor = 0xA0A0B;

    function Resource(){
      onProgress = () => log("onProgress");
      onReady = () => log("onReady");

      this.load = function(paths){
        PIXI.loader
          .add(paths)
          .on("progress",onProgress)
          .load(onReady);
      }
    }

    function Scene(){
      let frame = null;
      let release = null;
      return {
        "enter":(frameCallback,releaseCallback) => {
          if(release){
            release();
          }

          frame = frameCallback;
          release = releaseCallback;
        },
        "frame":() => {
          if(frame){
            frame();
          }
        }
      }
    }

    function Next(){
      const SIZE = {w:120,h:120};
      const SCALE = 0.6;

      let mono = null;

      let view = new PIXI.Graphics();
      view.x = SCREEN.w - SIZE.w - 10;
      view.y = SCREEN.h - SIZE.h - 10;
      view.lineStyle(2,0x33FF33,1);
      view.beginFill(0xFFFFFF);
      view.drawRect(0,0,SIZE.w,SIZE.h);
      view.endFill();

      get();

      function get(){
        let minoType = 0;
        if(mono){
          view.removeChild(mono.view);
          minoType = mono.getType();
        }
        mono = Mono();
        mono.view.scale.set(SCALE);
        mono.view.x = (SIZE.w - BLOCK_SIZE * SCALE) / 2;
        mono.view.y = (SIZE.h - BLOCK_SIZE * SCALE) / 2;
        view.addChild(mono.view);

        return minoType;
      }

      return {
        get:get,
        view:view,
      }
    }

    function Score(){
      const SIZE = {w:120,h:30};
      let scoreTotal = 0;
      let textView = null;

      let view = new PIXI.Graphics();
      view.x = SCREEN.w - SIZE.w - 10;
      view.y = 10;
      view.lineStyle(2,0x336633,1);
      view.beginFill(0xFFFFFF);
      view.drawRect(0,0,SIZE.w,SIZE.h);
      view.endFill();

      let labelView = new PIXI.Text("Score",{font:'bold 12pt Arial', fill:0x000000});
      labelView.position.x = 10;
      labelView.position.y = SIZE.h / 2;
      labelView.anchor.x = 0;
      labelView.anchor.y = 0.5;
      view.addChild(labelView);

      function render(){
        if(textView){
          view.removeChild(textView);
        }

        textView = new PIXI.Text("" + scoreTotal,{font:'bold 12pt Arial', fill:0x000000});
        textView.position.x = SIZE.w - 10;
        textView.position.y = SIZE.h / 2;
        textView.anchor.x = 1;
        textView.anchor.y = 0.5;
        view.addChild(textView);
      }

      return {
        clearScore:() => {
          scoreTotal = 0;
          render();
        },
        addScore:(score) => {
          scoreTotal += score;
          render();
        },
        scoreTotal:() => {return scoreTotal;},
        view:view,
      }
    }

    function Level(){
      let RANGE = {min:0,max:8};
      let value = 0;
      let textView = null;

      let SPEEDS = {
        0:60,
        1:50,
        2:40,
        3:30,
        4:20,
        5:10,
        6:8,
        7:6,
        8:4,
      };

      let view = new PIXI.Graphics();
      let SIZE = {w:120,h:30};
      view.x = SCREEN.w - SIZE.w - 10;
      view.y = 40;
      view.lineStyle(2,0x336633,1);
      view.beginFill(0xFFFFFF);
      view.drawRect(0,0,SIZE.w,SIZE.h);
      view.endFill();

      let labelView = new PIXI.Text("Level",{font:'bold 12pt Arial', fill:0xFF0000});
      labelView.position.x = 10;
      labelView.position.y = SIZE.h / 2;
      labelView.anchor.x = 0;
      labelView.anchor.y = 0.5;
      view.addChild(labelView);

      function render(){
        if(textView){
          view.removeChild(textView);
        }

        textView = new PIXI.Text("" + value,{font:'bold 12pt Arial', fill:0xFF0000});
        textView.position.x = SIZE.w - 10;
        textView.position.y = SIZE.h / 2;
        textView.anchor.x = 1;
        textView.anchor.y = 0.5;
        view.addChild(textView);
      }

      return {
        clearLevel:() => {
          value = RANGE.min;
          render();
        },
        addLevel:(minoCount) => {
          if(minoCount % 10 == 0){
            value = Math.min(RANGE.max,value + 1);
            render();
          }
        },
        getSpeed:() => {
          return SPEEDS[value];
        },
        view:view,
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

    function Outline(){
      const SIZE = {w:BLOCK_HORIZONTAL_NUM * BLOCK_SIZE,h:BLOCK_VERTICAL_NUM * BLOCK_SIZE};

      let table = null;

      let view = new PIXI.Graphics();
      view.x = (SCREEN.w - SIZE.w) / 2;
      view.y = (SCREEN.h - SIZE.h) / 2;
      view.lineStyle(2,0x33FF00,1);
      view.beginFill(0xFFFFFF);
      view.drawRect(0,0,SIZE.w,SIZE.h);
      view.endFill();

      let views = {};
      function key(x,y){
        return ""+y+":"+x;
      }

      function updateBlock(x,y){
        let block = blockFactory.create(table[y][x]);
        if(block){
          block.x = x * BLOCK_SIZE;
          block.y = y * BLOCK_SIZE;
          views[key(x,y)] = block;
          view.addChild(block);
        }
      }

      function updateBlockAll(){
        for(let key in views){
          view.removeChild(views[key]);
        }
        views = {};

        for(let y in table) {
          for(let x in table[y]){
            updateBlock(x,y);
          }
        }
      }

      return {
        clearTable:() => {
          table = new Array(BLOCK_VERTICAL_NUM).fill([]);
          for(let y in table) {
            table[y] = new Array(BLOCK_HORIZONTAL_NUM).fill(BLOCK_EMPTY);
          }
          updateBlockAll();
        },
        canMove:(mono,grid) => {
          for(let block of mono.prop.blocks){
            let x = block.x + grid.x;
            let y = block.y + grid.y;
            // if(y < 0) return false;
            if(x < 0) return false;
            if(BLOCK_VERTICAL_NUM <= y) return false;
            if(BLOCK_HORIZONTAL_NUM <= x) return false;
            if(0 <= y && table[y][x]) return false;
          }

          return true;
        },
        putBlock:(mono,grid) => {
          let overlapped = false;
          for(let block of mono.prop.blocks){
            let x = block.x + grid.x;
            let y = block.y + grid.y;
            overlapped = overlapped || table[y][x] != BLOCK_EMPTY;
            table[y][x] = block.pattern;
            updateBlock(x,y);
          }
          return overlapped;
        },
        deleteEffect:(callback) => {
          // 削除
          table = table.filter((line) => {
              return !line.every((value) => {return BLOCK_EMPTY != value;});
          });
          if(table.length < BLOCK_VERTICAL_NUM){
            let line = BLOCK_VERTICAL_NUM - table.length;
            score.addScore(line * line * 100);

            while(table.length < BLOCK_VERTICAL_NUM){
              let line = [new Array(BLOCK_HORIZONTAL_NUM).fill(BLOCK_EMPTY)];
              table = line.concat(table);
              updateBlockAll();
            }
          }

          callback();
        },
        view:view,
      }
    }

    function BlockFactory(){
      const PATTERNS = {
        // 0:{line:0x000000,fill:0xFFFFFF},
        1:{line:0xFF3300,fill:0xFFCCCC},
        2:{line:0xFF3300,fill:0xCCFFCC},
        3:{line:0xFF3300,fill:0xCCCCFF},
        4:{line:0xFF3300,fill:0xCCCCCC},
        5:{line:0xFF3300,fill:0xAACCFF},
        6:{line:0xFF3300,fill:0xFFAACC},
        7:{line:0xFF3300,fill:0xFFCCAA},
        9:{line:0x333333,fill:0xFFCCAA},
      }

      this.create = function(type){
        if(!PATTERNS[type]) return null;

        let style = PATTERNS[type]
        let view = new PIXI.Graphics();
        view.lineStyle(2,style.line,1);
        view.beginFill(style.fill);
        view.drawRect(0,0,BLOCK_SIZE,BLOCK_SIZE);
        view.endFill();
        return view
      }
    }

    function Mono(type = 0){
      let PATTERNS = {
        1:{
          blocks:[
            {x:1,y:0,pattern:1},
            {x:0,y:1,pattern:1},
            {x:1,y:1,pattern:1},
            {x:0,y:0,pattern:9},
          ],
          rect:{},
        },
        2:{
          blocks:[
            {x:-1,y:0,pattern:2},
            {x:1,y:0,pattern:2},
            {x:0,y:1,pattern:2},
            {x:0,y:0,pattern:9},
          ],
          rect:{},
        },
        3:{
          blocks:[
            {x:-1,y:0,pattern:3},
            {x:0,y:1,pattern:3},
            {x:1,y:1,pattern:3},
            {x:0,y:0,pattern:9},
          ],
          rect:{},
        },
        4:{
          blocks:[
            {x:-1,y:1,pattern:4},
            {x:0,y:1,pattern:4},
            {x:1,y:0,pattern:4},
            {x:0,y:0,pattern:9},
          ],
          rect:{},
        },
        5:{
          blocks:[
            {x:-1,y:0,pattern:5},
            {x:1,y:0,pattern:5},
            {x:1,y:1,pattern:5},
            {x:0,y:0,pattern:9},
          ],
          rect:{},
        },
        6:{
          blocks:[
            {x:-1,y:1,pattern:6},
            {x:-1,y:0,pattern:6},
            {x:1,y:0,pattern:6},
            {x:0,y:0,pattern:9},
          ],
          rect:{},
        },
        7:{
          blocks:[
            {x:-1,y:0,pattern:7},
            {x:1,y:0,pattern:7},
            {x:2,y:0,pattern:7},
            {x:0,y:0,pattern:9},
          ],
          rect:{},
        },
      }

      const KEYS = _.keys(PATTERNS);

      let container = new PIXI.Container();

      if(!type){
        type = _.sample(KEYS);
      }
      let prop = _.clone(PATTERNS[type]);

      let rect = {left:0,right:0,top:0,bottom:0};
      for(let b of prop.blocks){
        let block = blockFactory.create(b.pattern);

        rect.top = Math.min(rect.top,b.y);
        rect.bottom = Math.max(rect.bottom,b.y);
        rect.left = Math.min(rect.left,b.x);
        rect.right = Math.max(rect.right,b.x);

        block.x = b.x * BLOCK_SIZE;
        block.y = b.y * BLOCK_SIZE;
        b.view = block;
        container.addChild(block);
      }
      prop.rect = rect;

      let rotate = (direction) => {
        let rect = {left:0,right:0,top:0,bottom:0};
        for(let b of prop.blocks){
          let _x = b.x
          if(0 < direction){
            b.x = -b.y;
            b.y = _x;
          }
          else{
            b.x = b.y;
            b.y = -_x;
          }

          rect.top = Math.min(rect.top,b.y);
          rect.bottom = Math.max(rect.bottom,b.y);
          rect.left = Math.min(rect.left,b.x);
          rect.right = Math.max(rect.right,b.x);

          let block = b.view;
          block.x = b.x * BLOCK_SIZE;
          block.y = b.y * BLOCK_SIZE;
        }
        prop.rect = rect;
      }

      return {
        view:container,
        getType:() => {return type;},
        prop:prop,
        rotate:rotate,
        rollback:() => {
          rotate(-1)
        }
      }
    }

    let stats = new Stats();
    stats.setMode(0);

    function Player(){
      let mono = null;
      let parentView = null;
      let frameCount = 0;
      let minoCount = 0;
      let grid = {x:0,y:0};

      // gridから実座標への変換
      function render(){
        mono.view.x = grid.x * BLOCK_SIZE;
        mono.view.y = grid.y * BLOCK_SIZE;
      }

      function move(gx,gy){
        let old_grid = _.clone(grid);
        grid.x += gx;
        grid.y += gy;

        let rollback = false;
        rollback = rollback || grid.x < -mono.prop.rect.left;
        rollback = rollback || BLOCK_HORIZONTAL_NUM - mono.prop.rect.right - 1 < grid.x;
        rollback = rollback || BLOCK_VERTICAL_NUM - mono.prop.rect.bottom - 1 < grid.y;
        rollback = rollback || !outline.canMove(mono,grid);

        if(rollback){
          grid = old_grid;
          if(0 < gy){
            // 落下確定
            if(outline.putBlock(mono,grid)){
              initGameOver();
              return false;
            }
            else{
              outline.deleteEffect(() => {player.show(parentView);});
            }
          }
        }

        render();
        return !rollback;
      }

      function rotate(direction){
        mono.rotate(direction);

        let rollback = false;
        rollback = rollback || grid.x < -mono.prop.rect.left;
        rollback = rollback || BLOCK_HORIZONTAL_NUM - mono.prop.rect.right - 1 < grid.x;
        rollback = rollback || BLOCK_VERTICAL_NUM - mono.prop.rect.bottom - 1 < grid.y;
        rollback = rollback || !outline.canMove(mono,grid);
        if(rollback){
          mono.rollback();
        }
        render();
      }

      let show = () => {
        frameCount = 0;
        ++minoCount;
        level.addLevel(minoCount);
        if(mono){
          parentView.removeChild(mono.view);
        }

        mono = Mono(next.get());
        grid.x = BLOCK_POSITION_GRID.x;
        grid.y = BLOCK_POSITION_GRID.y;
        parentView.addChild(mono.view);
        render();
      };

      return {
        init:(parent) => {
          parentView = parent;
          minoCount = 0;
          grid = {x:0,y:0};
          show();
        },
        show:show,
        moveHandler:(gx,gy) => {
          return () => {
            move(gx,gy);
          }
        },
        fallHandler:(gx,gy) => {
          return () => {
            move(gx,gy);
            score.addScore(1);
          }
        },
        skipHandler:(gx,gy) => {
          return () => {
            while(move(gx,gy)){
              score.addScore(1);
            }
          }
        },
        rotateHandler:(direction) => {
          return () => {
            rotate(direction);
          }
        },
        fall:(gx,gy) => {
          ++frameCount;
          if(frameCount % level.getSpeed() == 0){
            move(gx,gy);
          }
        },
      }
    }

    // キャンバス初期化
    let scene = Scene();
    function initGame(){
      let left = keyboard(37);
      let right = keyboard(39);
      let up = keyboard(38);
      let down = keyboard(40);
      let space = keyboard(32);

      scene.enter(
        () => {
          player.fall(0,1);
          renderer.render(sceneScreen);
        },
        () => {
          left.removeEventAll();
          right.removeEventAll();
          up.removeEventAll();
          down.removeEventAll();
          space.removeEventAll();
        }
      );

      score.clearScore();
      level.clearLevel();
      player.init(outline.view);
      outline.clearTable();

      sceneScreen.addChild(outline.view);
      sceneScreen.addChild(next.view);
      sceneScreen.addChild(score.view);
      sceneScreen.addChild(level.view);

      // キー入力
      right.repeat = right.press = player.moveHandler(1,0);
      left.repeat = left.press = player.moveHandler(-1,0);
      down.repeat = down.press = player.fallHandler(0,1);
      up.press = player.skipHandler(0,1);
      space.press = player.rotateHandler(1);
    }

    function initGameOver(){
      let space = keyboard(32);
      scene.enter(
        () => {
          renderer.render(sceneScreen);
        },
        () => {
          space.removeEventAll();
        }
      );

      space.press = () => {
        location.reload();
      };

      let result = Result();
      result.showResult();
      sceneScreen.addChild(result.view);
    }

    // メインループ
    let mainLoop = function(window){
      // log("mainLoop")

      stats.begin();

      scene.frame();

      stats.end();

      window.requestAnimationFrame(() => mainLoop(window));
    };

    // エントリポイント
    this.run = function(body,window){
      initGame();
      mainLoop(window);

      // renderer > PIXI.Stage -> PIXI.Container -> PIXI.Graphics
      body.append(renderer.view);
      renderer.render(sceneScreen);
      body.append(stats.domElement);
    }
  }

  new App().run(document.body,window);
}


export default {
}
</script>
