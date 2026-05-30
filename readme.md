# TODO

Hosting
- [x] Super basic setup
- [x] CI/CD to deploy
- [x] Basic hosting of the application
- [x] Basic login system
- [x] Get a domain and route it to website

- [x] Welcome page
- [ ] Leaderboard
    - [ ] Leaderboard view on home page
    - [ ] Store points for every event

Side Quests
- [ ] Riddles
    - [ ] Find 3 riddles
- [ ] Scavenger hunt
    - [ ] Ask Maison what this will look like
- [ ] Sword fighting
    - [ ] Ask Maison what her vision is here
    - [ ] Placeholder combat matches per user
        - Have a drop down of other users
        - Award points for winning matches
        - Cap points
        - Have a history of matches
- [ ] Mystic arts

Events
- [ ] Market
    - Instructions where to setup the market
- [ ] Performance lineup
    - Write down the times and the performers
    - Have the UI show the current time and what's coming next
- [ ] Potluck
    - Write down instructions for the potluck
- [ ] Donations + Charity (cash + etransfer)
    - What the donations are for
    - Where to send etransfer
    - Where to put cash (beggar?)

Main Quests
- [ ] Potion Quiz
    - Answer key? Multiple choice or you just have to guess?
- [ ] Archery
    - Award points based on accuracy?
- [ ] Hobby horse races
- [ ] King's court jousting (bracket generator)
    - Generate a tournament bracket thing based on folks who sign up

- [ ] Costume voting
    - Based on name

Tournament
- Points accumulated over other events
- Leaderboard style
- Winners will go into the final tournament

---

## Deployment

The app is configured to deploy to [Fly.io](https://fly.io). A `Dockerfile` and GitHub Actions workflow (`.github/workflows/deploy.yml`) are already set up. You just need to do the one-time Fly.io setup below.

### Data persistence

The app uses Storail (file-based JSON) at `./data` inside the container. This data is wiped on every redeploy. To persist data across deploys, create a Fly.io volume and mount it:

```sh
fly volumes create rennyaysance_data --size 1
```

Then add to `fly.toml`:

```toml
[mounts]
  source = "rennyaysance_data"
  destination = "/app/data"
```

---

### Useful commands

```sh
fly logs        # View logs
fly logs -f     # Tail logs in real time
fly status      # Check machine status
fly ssh console # SSH into the running container
```
