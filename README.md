# One Word Story Bot

A bot to host and moderate one-word story games.

### Invite Link
https://discord.com/oauth2/authorize?client_id=717854442577330390&scope=bot&permissions=339008

## How To Play

Type !story in any channel to start a new game. If enough players join within two minutes, the
story will begin and the channel will be locked* until the story ends. The story will end when
the phrase "the end" is inputted, or the story-initiator types !stopstory.

*Messages sent in the channel where the game was initiated are considered an entry for the
story and are therefore deleted. Because of this, You may want to create a separate
channel soley for one-word-stories as to not interupt the flow of a conversation. Command(s)
that restrict games to certain channels may be implemented in the future.

## Commands
* !story [optional story title] - Waits for players to join the game (via a message reaction) before starting.
* !startstory - Skip the player wait time (2 minutes) for an active game.
* !stopstory - Stop a story manually.
* !help - Gives information on each command and how to play.