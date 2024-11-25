// board var
let board;
let boardwidth = 360;
let boardheight = 640;
let context;
let g = document.getElementById("board");

// music

let sound1 = new Audio("music/toy-button-105724.mp3");
sound1.playbackRate = 5.5;
let sound2 = new Audio("music/hit.mp3.wav");

// bird var
let birdwidth = 34;
let birdheight = 24
let birdx = boardwidth / 8;
let birdy = boardheight / 2;
let birdimg;
let bird = {
    x: birdx,
    y: birdy,
    width: birdwidth,
    height: birdheight,
}
// pipes
let pipesarr = [];
let pipewidht = 64;
let pipeheight = 512;
let pipex = boardwidth;
let pipey = 0;


let toppipe;
let toppipeimg;
let bottompipe;
let bottompipeimg;
// restest button
let gameeover = document.getElementById("gameover");
let playagain = document.getElementById("again");
// start

let start = document.getElementById("start");
let startbtn = document.getElementById("startgame");

//velocity
let velocityx = -2;
let velocity = 0;
let gravity = 0.3;
let score = 0;
let gameover = false;
let up = document.getElementById("up");

let imagesLoaded = 0;
let totalImages = 3;
function imageLoaded() {
    imagesLoaded++;
    if (imagesLoaded === totalImages) {
        setInterval(placepipe, 1500);
        requestAnimationFrame(update);
    }
}
imageLoaded();

startbtn.addEventListener("click",function(){
    start.style.display = "none";
    g.style.display = "block";
    firstfun();
})

 function  firstfun() {
    board = document.getElementById("board");
    board.width = boardwidth;
    board.height = boardheight;
    context = board.getContext("2d"); // use board work
    // draw flappy bird

    // context.fillStyle = "green";
    // context.fillRect(bird.x, bird.y, bird.width, bird.height );

    birdimg = new Image();
    birdimg.src = "images/birdimg.png";
    birdimg.onload = imageLoaded();
    toppipeimg = new Image();
    toppipeimg.src = "images/khambaimg.png";
    toppipeimg.onload = imageLoaded();
    bottompipeimg = new Image();
    bottompipeimg.src = "images/btoomkhambaimg.png";
    bottompipeimg.onload = imageLoaded();

    document.addEventListener("keydown", movebird);



}


function update() {
    requestAnimationFrame(update);
    if (gameover) {
        return
    }
    context.clearRect(0, 0, boardwidth, boardheight);

    //darw bird
    velocity += gravity;
    bird.y = Math.max(bird.y + velocity, 0);
    context.drawImage(birdimg, bird.x, bird.y, bird.width, bird.height);

    if (bird.y > boardheight) {
        gameover = true;
        gameeover.style.display = "block";
    }
    // pipe
    for (let i = 0; i < pipesarr.length; i++) {
        let pipe = pipesarr[i];
        pipe.x += velocityx;
        context.drawImage(pipe.img, pipe.x, pipe.y, pipe.width, pipe.height);
        if (!pipe.passed && bird.x > pipe.x + pipe.width) {
            score += 0.5;
            pipe.passed = true;
        }
        if (collision(bird, pipe)) {
            sound2.play();
            gameover = true;
        }
    }
    while (pipesarr.length > 0 && pipesarr[0].x < -pipewidht) {
        pipesarr.shift();
    }


    // score 
    context.fillStyle = "white";
    context.font = "45px sans-serif";
    context.fillText(score, 5, 45);

    if(gameover){
        gameeover.style.display = "block";
    }

}
function placepipe() {
    if (gameover) {
        return
    }
    /////////////////// 0 /////// 128 ////////// 0.something ////// 256
    let randompipey = pipey - pipeheight / 4 - Math.random() * (pipeheight / 2);
    let open = board.height / 4;
    let toppipe = {
        img: toppipeimg,
        x: pipex,
        y: randompipey,
        width: pipewidht,
        height: pipeheight,
        passed: false,
    }
    pipesarr.push(toppipe)

    let bottompipe = {
        img: bottompipeimg,
        x: pipex,
        y: randompipey + open + pipeheight,
        width: pipewidht,
        height: pipeheight,
        passed: false,
    }
    pipesarr.push(bottompipe)

}
playagain.addEventListener("click", function () {
    bird.y = birdy;
    pipesarr = [];
    score = 0;
    velocity = -6;
    gameover = false;
    gameeover.style.display = "none";  
})

function movebird(e) {
    if (e.code == "Space" || e.code == "ArrowUp") {
        velocity = -6;
        sound1.play();
    }
        
}
up.addEventListener("click",()=>{
    velocity = -6;
    sound1.play();
})

function collision(a, b) {
    return a.x < b.x + b.width &&
        a.x + a.width > b.x &&
        a.y < b.y + b.height &&
        a.y + a.height > b.y;
}