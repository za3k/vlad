## What is Vlad?
Vlad (the remailer) is a team productivity tool closely based on a similar system at Google. Once a day, Vlad emails everyone in the group, asking what they did. The next morning, he sends an email to the group with what everyone did.

I found this tool very useful to my productivity. It holds you accountable, and helps your organize your thoughts on how long-term tasks are going.

## Email example

Each day you get an email with the subject: `Vat did you do today? 2023-04-16`

```

Hey Zak,


Vat did you do today (2023-04-16)?

Vork, chores, coding, conversations, anything... or nothing.  Just reply to this email and VladTheRemailer vill send out a compilation tomorrow morning.

- Vlad The Remailer
```

You can then respond any time that day or the next morning.

Then Vlad sends out a summary (``) to everyone on the list:

```
Zak report on 2023-04-16:

- Did weekly transcription
- Did weekly review, catch-up monthly review
- Fixed Vlad timezones to be EST, not PST
- Dropped off something for my sister, and picked up the blast furnace we
made. Forgot fire bricks.
- Made a salad
- Failed to get TP-LINK to work (pocket router), ordered new one for next
time
- Solved a couple puzzles with Steve
- Did the 2020 #ircpuzzles writeup


Jen report on 2023-04-16:

- No snippets submitted
```


## To install vlad
1. Drop him somewhere
2. Change the list of email addresses to target
3. Run 'bundle install'
4. Edit crontab.  --solicit is the email requesting responses.  --summary is the email for sending out the responses after they're received.  Picking a good time of day for each is important.  (I like to send out the summary before anyone is awake, but the "solicit" email is trickier to decide)
    0  2 * * * /usr/bin/ruby ~vlad/vlad.rb --solicit
    0 12 * * * /usr/bin/ruby ~vlad/vlad.rb --summary
5. You're done.
