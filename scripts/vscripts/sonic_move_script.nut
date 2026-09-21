// Sonic CD Special Stage Recreation
// Written By LittleBlueBox
// Note: If you are going to use this script, be sure to give credit to:
	// SEGA, for creating Sonic CD
	// Christian Whitehead, for creating Sonic CD (2011)
	// LittleBlueBox, for creating the script itself

// This script is a bit messy and also requires some entities to be named exactly as how they're found in the EntFire calls (unless you changed them of course)

// Entity Handles
sonic <- EntityGroup[0]			// Sonic's main sprite (in the map, I used sonic_walk as the main parent)
playerTpPos <- EntityGroup[1]		// Player's teleport pos (this is an entity parented to the sonic entity found above)
cameraPos <- EntityGroup[2]		// Camera tracking point (this is a seperate entity that is at the same horizontal position as sonic, but no height changes)

// General movement variables
canMove <- false
isInAir <- false
isJumping <- false

// Ground related variables
playerVel <- 0
maxPlayerVel <- 16
maxPlayerVelShoes <- 35
targetSpdManual <- false
turnCounter <- 0
hasSpeedShoes <- false
targetMaxSpd <- 0

// Air related variables
initialJumpHeldTime <- 0
jumpMaxHeldTime <- 0.5
jumpStartSpeed <- 5
//jumpHoldSpeed <- 2
maxFallSpeed <- 5
verticalSpeed <- 0
gravity <- 0.6
forceFall <- false

// Spike related variables
isHurt <- false
isRecover <- false
inSpikes <- false

// Water related variables
inWater <- false

// Bumper related variables
bumper <- false
bumperTimer <- 0

// Intro related variables
isIntro <- true
startMap <- false

// Ending related variables
finishMap <- false

// Score related variables
rings <- 0
time <- 100

curSprite <- null

heldKeys <- {
	left = false,
	right = false,
	jump = false
}

function setSprite(spriteName = null)
{
	if (curSprite == spriteName)
	{
		return
	}

	// Only try to hide a sprite if the previous sprite exists (only really used for intro)
	if (curSprite != "" && curSprite != null)
	{
		EntFire("sonic_" + curSprite, "hidesprite")
	}

	EntFire("sonic_" + spriteName, "showsprite")

	curSprite = spriteName
}

function changeSprite()
{

	//printl("intro?: " + isIntro)
	//printl("move?: " + canMove)

	if (isRecover)
	{
		setSprite("hurt_get_up")
		turnCounter = 0
		return
	}

	if (isHurt && canMove)
	{
		setSprite("hurt")
		turnCounter = 0
		return
	}

	if (isHurt && !canMove)
	{
		setSprite("hurt_idle")
		turnCounter = 0
		return
	}

	// Change Sonic's animation to a jumping state
	if (isInAir && isJumping)
	{
		setSprite("jump")
		return
	}

	// Change Sonic's animation to a spinning fan state
	// The only way for sonic to become airborne is through jumping, or touching fans on the floor that blow him upwards
	else if (isInAir && !isJumping)
	{
		setSprite("fan")
		return
	}

	// Intro finger wagging animaton
	if (!canMove && isIntro)
	{
		setSprite("intro")
		turnCounter = 0
		EntFire("sonic_move_script", "RunScriptCode", "isIntro = false", 1.9)
		return
	}

	// Standing still (used for after the intro finishes)
	if ((!canMove || playerVel == 0) && !isIntro)
	{
		setSprite("idle")
		turnCounter = 0
		return
	}

	// Running
	if (abs(playerVel) >= 20 && !isInAir)
	{
		setSprite("run")
		turnCounter = 0
		return
	}

	// Turning Left
	if (heldKeys.left && !heldKeys.right && !isInAir && !bumper)
	{

		if (turnCounter <= 5)
		{
			setSprite("walk_soft_turn_left")
			turnCounter += 1
		}

		else
		{
			setSprite("walk_hard_turn_left")
			turnCounter = 999
		}

		return
	}

	// Turning Right
	else if (heldKeys.right && !heldKeys.left && !isInAir && !bumper)
	{

		if (turnCounter <= 5)
		{
			setSprite("walk_soft_turn_right")
			turnCounter += 1
		}

		else
		{
			setSprite("walk_hard_turn_right")
			turnCounter = 999
		}

		return
	}

	// Walking forward
	else if (heldKeys.left == heldKeys.right && !isInAir)
	{
		setSprite("walk")

		turnCounter = 0

		return
	}
}


function turnLeft()
{

	if (heldKeys.right || isHurt)
	{
		return
	}

	sonic.SetAngles(sonic.GetAngles().x, sonic.GetAngles().y + 5, 0)
	cameraPos.SetAngles(sonic.GetAngles().x, sonic.GetAngles().y + 5, 0)
}

function turnRight()
{

	if (heldKeys.left || isHurt)
	{
		return
	}

	sonic.SetAngles(sonic.GetAngles().x, sonic.GetAngles().y - 5, 0)
	cameraPos.SetAngles(sonic.GetAngles().x, sonic.GetAngles().y - 5, 0)
}

function playerJumpInitialPress()
{
	if (!canMove || isInAir || isHurt)
	{
		return
	}

	isJumping = true
	initialJumpHeldTime = Time()
	verticalSpeed = jumpStartSpeed
	isInAir = true
	inWater = false

	turnCounter = 0
	EntFire("jump_sfx", "playsound")
	EntFire("splash_effect_time", "Disable")
	EntFire("splash_effect", "Stop")
}


function spike()
{

	// Sonic can only get hurt when touching spikes (which are on the ground)
	// Getting hurt while landing causes sonic to remain airborne until the hurt animation finishes due to the trigger needing to be slightly above ground to trigger

	if (isHurt)
	{
		return
	}

	isHurt = true
	inSpikes = false

	if (rings > 0)
	{
		EntFire("ring_loss_sfx", "playsound")
	}

	rings -= 10
	EntFire("sonic_move_script", "runscriptcode", "canMove = false", 0.5)
	EntFire("sonic_move_script", "runscriptcode", "canMove = true", 2.4)
	EntFire("sonic_move_script", "runscriptcode", "isHurt = false", 2)
	EntFire("sonic_move_script", "runscriptcode", "isRecover = true", 2)
	EntFire("sonic_move_script", "runscriptcode", "isRecover = false", 2.4)
}

function initialSpikeTouch()
{

	if (isHurt)
	{
		return
	}

	// This variable tracks if Sonic is in the spike
	// This is so that we can track if not Sonic has LANDED, because if he's in the air, he can't take damage
	inSpikes = true

	if (!isInAir && !isHurt && !isJumping)
	{
		spike()
	}
}

function subtractTime(amount = 1)
{
	// Custom function to better allow for time subtraction
	// only works if both time and amount are numbers (aka integers or floats)
	// this also means that if either one of these arent numbers, then the level is infinite, which helps with testing and such
	// also also, this prevents errors from occuring if you try to just take away time directly from the variable when it's not set correctly

	if ((typeof(time) == "integer" || typeof(time) == "float") && (typeof(amount) == "integer" || typeof(amount) == "float"))
	{
		time -= amount
	}

	EntFire("timer_100s_place", "addoutput", "frame " + (floor(time / 100)))
	EntFire("timer_10s_place", "addoutput", "frame " + ((floor(time / 10)) % 10))
	EntFire("timer_1s_place", "addoutput", "frame " + time % 10)
}

function bumperInitTouch(dir = 1)
{
	if (isInAir)
	{
		return
	}

	bumper = true
	bumperTimer = Time()
	playerVel = maxPlayerVel // 2 * -1

// Despite writing the code below, I thought it might take too long to implement for EACH trigger
// so, the timplified version just moves sonic away in the opposite direction he touched it in

/*
	local plusOrMinus = "+"

	if (dir == 1)
	{
		if (sonic.GetOrigin().x > caller.GetOrigin().x)
		{
			plusOrMinus = "+"
		}

		else
		{
			plusOrMinus = "-"
		}
	}

	else if (dir == 2)
	{
		if (sonic.GetOrigin().y > caller.GetOrigin().y)
		{
			plusOrMinus = "+"
		}

		else
		{
			plusOrMinus = "-"
		}
	}

	else
	{
		dir = 1
	}

	bumpDirection = plusOrMinus + dir
*/
}

//----------------------------------------------------------------------------------------------------------------------------------
function moveSonic()
{
	//printl(isHurt)
	//printl(inWater)
	//printl(time)

	if (!canMove && finishMap)
	{
		if (cameraPos.GetAngles().y != (sonic.GetAngles().y + 180))
		{
			cameraPos.SetAngles(cameraPos.GetAngles().x, cameraPos.GetAngles().y + 1, cameraPos.GetAngles().z)
		}

		return
	}

	if (!canMove && !startMap)
	{
		isInAir = false
		isJumping = false
		//isHurt = false
		return
	}

	// Check if the time is less than or equal to 0, and if so, end the level prematurely
	if (time <= 0)
	{
		EntFire("finish_map_relay","trigger")
	}

	if (!isInAir && finishMap)
	{
		canMove = false
		EntFire("finish_map_relay", "trigger")
/*
		while (cameraPos.GetAngles().y != sonic.GetAngles().y)
		{
			cameraPos.SetAngles(cameraPos.GetAngles().x, cameraPos.GetAngles().y + 1, cameraPos.GetAngles().z)
		}
*/

		return
	}

	if (!isInAir && inWater)
	{
		EntFire("splash_effect_time", "Enable")
		//EntFire("splash_effect", "Start")
	}
	else
	{
		EntFire("splash_effect_time", "Disable")
		//EntFire("splash_effect", "Stop")
	}

	if (heldKeys.left == true && !bumper)
	{
		turnLeft()
	}

	if (heldKeys.right == true && !bumper)
	{
		turnRight()
	}


	// Determine Sonic's target speed based on if we have speed shoes active
	if (!targetSpdManual)
	{
		targetMaxSpd = hasSpeedShoes ? maxPlayerVelShoes : maxPlayerVel
	}

	// When Sonic gets hurt, he INSTANTLY loses speed. He doesn't stop immediately though, and he slides on the floor for a little bit before fully stopping
	if (isHurt)
	{
		targetMaxSpd = 0
		if (playerVel > 6)
		{
			playerVel = 6
		}
	}

	if (playerVel < targetMaxSpd)
	{
		playerVel += 1
	}

	else if (playerVel > targetMaxSpd)
	{
		playerVel -= 1
	}

	if (bumper)
	{
		local timeBeforeBumperReset = Time() - bumperTimer

		if (timeBeforeBumperReset >= 1.5)
		{
			bumper = false
		}

		else
		{
			playerVel = maxPlayerVel // 2 * -1
		}
	}

	//printl(playerVel)

	EntFire("sonic_walk*", "addoutput", "framerate " + playerVel)
	//EntFire("sonic_run", "addoutput", "framerate " + playerVel)

	local radians = sonic.GetAngles().y * PI / 180

	local forward = Vector(cos(radians) * playerVel, sin(radians) * playerVel, 0)


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	if (isJumping)
	{
		local holdDuration = Time() - initialJumpHeldTime

		// Variable Height (how high Sonic can jump while holding jump)
		if (heldKeys.jump && holdDuration < jumpMaxHeldTime && !forceFall)
		{
			/*
			local maxJumpSpeed = jumpStartSpeed + jumpHoldSpeed

			if (verticalSpeed < maxJumpSpeed)
			{
				verticalSpeed = maxJumpSpeed
			}
			*/

			verticalSpeed = jumpStartSpeed
		}

		if (heldKeys.jump && holdDuration > jumpMaxHeldTime)
		{
			forceFall = true
		}

		// release jump early = start falling immediately
		if (!heldKeys.jump)
		{
			forceFall = true
		}

	}
		

	verticalSpeed -= gravity

	if (verticalSpeed < -maxFallSpeed)
	{
		verticalSpeed = -maxFallSpeed
	}


	cameraPos.SetOrigin(Vector(sonic.GetOrigin().x, sonic.GetOrigin().y, cameraPos.GetOrigin().z) + forward)
	cameraPos.SetAngles(sonic.GetAngles().x, sonic.GetAngles().y, sonic.GetAngles().z)
	sonic.SetOrigin(sonic.GetOrigin() + forward + Vector(0, 0, verticalSpeed))

	EntFire("player", "AddOutput", "origin " + playerTpPos.GetOrigin().x + " " + playerTpPos.GetOrigin().y + " " + playerTpPos.GetOrigin().z)
	EntFire("player", "AddOutput", "movetype 0")
	EntFire("player", "AddOutput", "angles " + sonic.GetAngles().x + " " + sonic.GetAngles().y + " " + sonic.GetAngles().z)


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Bounds Checking
// If Sonic is further than these bounds, snap him to the outside of the wall/floor (in a way, sorta like early 3d games like SM64)
// As of right now, these bounds are meant for the walls and floor of the test room. the room's floor should (ideally) not change during development, only the walls should

	// Walls (-x, +x)
	if (sonic.GetOrigin().x < -427)
	{
		sonic.SetOrigin(Vector(-427, sonic.GetOrigin().y, sonic.GetOrigin().z))
	}

	else if (sonic.GetOrigin().x > 811)
	{
		sonic.SetOrigin(Vector(811, sonic.GetOrigin().y, sonic.GetOrigin().z))
	}

	// Walls (-y, +y)
	if (sonic.GetOrigin().y < -811)
	{
		sonic.SetOrigin(Vector(sonic.GetOrigin().x, -811, sonic.GetOrigin().z))
	}

	else if (sonic.GetOrigin().y > 427)
	{
		sonic.SetOrigin(Vector(sonic.GetOrigin().x, 427, sonic.GetOrigin().z))
	}

	// We use an elseif for walls on the same axis (-x, +x) & (-y, +y) because these can't BOTH be true at the same time.

	// Floor
	if (sonic.GetOrigin().z < 88)
	{
		sonic.SetOrigin(Vector(sonic.GetOrigin().x, sonic.GetOrigin().y, 88))
		isJumping = false
		verticalSpeed = 0
		initialJumpHeldTime = 0
		isInAir = false
		forceFall = false

		if (inSpikes && !isHurt)
		{
			spike()
		}

	}
		
}