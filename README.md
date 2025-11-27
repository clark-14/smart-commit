# Smart Commit

**Smart Commit** is a lightweight shell tool that streamlines your Git
workflow using optional AI-generated commit messages. It supports
different modes, from fully automatic commits to manual or verbose
debugging output.

## Features

-   AI-generated commit messages
-   Manual commit mode (no AI)
-   Verbose explanation mode
-   Fast mode for instant commit without menus
-   Compatible with any Git repository

## Usage

Run the script from your project root:

``` bash
./smart-commit.sh
```

### Modes

  -----------------------------------------------------------------------------------
  Command                                 Description
  --------------------------------------- -------------------------------------------
  `./smart-commit.sh`                     Uses AI and displays only a concise commit
                                          message.

  `./smart-commit.sh --no-ai`             Disables AI and performs a manual commit.

  `./smart-commit.sh --verbose`           Uses AI and shows a detailed explanation.

  `./smart-commit.sh --no-ai --verbose`   Disables AI but enables verbose output.

  `./smart-commit.sh --fast`              AI mode + commits instantly without menu.
  -----------------------------------------------------------------------------------

## Installation

``` bash
chmod +x smart-commit.sh
```

(Optional) Move it into your PATH:

``` bash
sudo mv smart-commit.sh /usr/local/bin/smart-commit
```

## License

MIT License
