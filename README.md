# Telegram Bot for kdmid

## Usage

### Running the bot

Create .env file and replace variables with your values:

    $ cp .env.example .env

Build docker images:

    $ make app-build

After this you need to create and migrate your database:

    $ make app-prepare-db

And up everything:

    $ make app-up

Great! Now you can easily start your bot just by running this command:

## Contributing

If you have some proposals how to improve this bot feel free to open issues and send pull requests!

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request
