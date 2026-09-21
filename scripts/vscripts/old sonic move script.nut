// Hey! This script is from the old beta version of the SCD Special Stage recreation (aside from this comment & the header of course).
// For the most part, this version is the same as the new version in terms of movement code. Items and stage hazards were not coded yet at this point.
// I simply kept this code to have as reference, in case i SERIOUSLY messed something up.

// Sonic CD Special Stage Recreation
// Written By LittleBlueBox

sonic <- EntityGroup[0]
playerTpPos <- EntityGroup[1]
cameraPos <- EntityGroup[2]

canMove <- false
isInAir <- false
isJumping <- false
playerVel <- 0
maxPlayerVel <- 16
maxPlayerVelShoes <- 35
initialJumpHeldTime <- 0
jumpMaxHeldTime <- 0.5
jumpStartSpeed <- 3
jumpHoldSpeed <- 2
maxFallSpeed <- 5
verticalSpeed <- 0
gravity <- 0.6
forceFall <- false
turnCounter <- 0
isHurt <- false
isIntro <- true
hasSpeedShoes <- false
finishMap <- false

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

	if (isHurt)
	{
		setSprite("hurt")
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
	if (!canMove && !isIntro)
	{
		setSprite("idle")
		turnCounter = 0
		return
	}

	if (playerVel >= 20 && !isInAir)
	{
		setSprite("run")
		turnCounter = 0
		return
	}

	if (heldKeys.left && !heldKeys.right && !isInAir)
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

	else if (heldKeys.right && !heldKeys.left && !isInAir)
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

	else if (heldKeys.left == heldKeys.right && !isInAir)
	{
		setSprite("walk")

		turnCounter = 0

		return
	}
}


function turnLeft()
{

	if (heldKeys.right)
	{
		return
	}

	sonic.SetAngles(sonic.GetAngles().x, sonic.GetAngles().y + 5, 0)
	cameraPos.SetAngles(sonic.GetAngles().x, sonic.GetAngles().y + 5, 0)
}

function turnRight()
{

	if (heldKeys.left)
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

	turnCounter = 0
	EntFire("jump_sfx", "playsound")
}




function moveSonic()
{
	if (!canMove)
	{
		isInAir = false
		isJumping = false
		isHurt = false
		return
	}

	if (!isInAir && finishMap)
	{
		canMove = false
		EntFire("finish_map_relay", "trigger")
		return
	}

	if (heldKeys.left == true)
	{
		turnLeft()
	}

	if (heldKeys.right == true)
	{
		turnRight()
	}


	if (!hasSpeedShoes)
	{
		playerVel += 1

		if (playerVel > maxPlayerVel)
		{
			playerVel -= 2
		}
	}

	else
	{
		playerVel += 1

		if (playerVel > maxPlayerVelShoes)
		{
			playerVel = maxPlayerVelShoes
		}
	}

	local radians = sonic.GetAngles().y * PI / 180

	local forward = Vector(cos(radians) * playerVel, sin(radians) * playerVel, 0)


	//////////////////////////////////////////////////////////////////////////////////////


	if (isJumping)
	{
		local holdDuration = Time() - initialJumpHeldTime

		// Variable Height (how high Sonic can jump while holding jump)
		if (heldKeys.jump && holdDuration < jumpMaxHeldTime && !forceFall)
		{
			local maxJumpSpeed = jumpStartSpeed + jumpHoldSpeed

			if (verticalSpeed < maxJumpSpeed)
			{
				verticalSpeed = maxJumpSpeed
			}
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


	/////////////////////////////////////////////////////////////////////////////////////////////////


	if (sonic.GetOrigin().x < -427)
	{
		sonic.SetOrigin(Vector(-427, sonic.GetOrigin().y, sonic.GetOrigin().z))
	}

	else if (sonic.GetOrigin().x > 811)
	{
		sonic.SetOrigin(Vector(811, sonic.GetOrigin().y, sonic.GetOrigin().z))
	}

	if (sonic.GetOrigin().y < -811)
	{
		sonic.SetOrigin(Vector(sonic.GetOrigin().x, -811, sonic.GetOrigin().z))
	}

	else if (sonic.GetOrigin().y > 427)
	{
		sonic.SetOrigin(Vector(sonic.GetOrigin().x, 427, sonic.GetOrigin().z))
	}

	if (sonic.GetOrigin().z < 88)
	{
		sonic.SetOrigin(Vector(sonic.GetOrigin().x, sonic.GetOrigin().y, 88))
		isJumping = false
		verticalSpeed = 0
		initialJumpHeldTime = 0
		isInAir = false
		forceFall = false
	}
		
}