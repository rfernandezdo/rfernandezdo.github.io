---
draft: false
date: 2024-12-21
authors:
  - rfernandezdo
categories:
    - Visual Studio Code
tags:
    - Git
---
# How to sign Git commits in Visual Studio Code in Windows Subsystem for Linux (WSL)

In this post, we will see how to sign Git commits in Visual Studio Code.

## Prerequisites

- Visual Studio Code
- Git
- GPG
- GPG agent
- Windows Subsystem for Linux (WSL) with Ubuntu 20.04

## Steps

### 1. Install GPG

First, you need to install GPG ans agents. You can do this by running the following command:

```bash
sudo apt-get install gpg gpg-agent gpgconf
```

### 2. Generate a GPG key

To generate a GPG key, run the following command:

```bash
gpg --full-generate-key
```

You will be asked to enter your name, email, and passphrase. After that, the key will be generated.

### 3. List your GPG keys

To list your GPG keys, run the following command:

```bash
gpg --list-secret-keys --keyid-format LONG
```

You will see a list of your GPG keys. Copy the key ID of the key you want to use.

### 4. Configure Git to use your GPG key

To configure Git to use your GPG key, run the following command:

```bash
git config --global user.signingkey YOUR_KEY_ID
```

Replace `YOUR_KEY_ID` with the key ID you copied in the previous step.

### 5. Configure Git to sign commits by default

To configure Git to sign commits by default, run the following command:

```bash

git config --global commit.gpgsign true
```

### 6. EXport the GPG key 

To export the GPG key, run the following command:

```bash
gpg --armor --export YOUR_KEY_ID
```

Replace `YOUR_KEY_ID` with the key ID you copied in the previous step.

### 7. Import to github

Go to your [github account](https://github.com/settings/keys) and add the exported GPG key in GPG keys section.

### Configure Visual Studio Code to use GPG
#### 1. Configure gpg-agent

To configure gpg-agent, run the following command:

```bash
echo "default-cache-ttl" >> ~/.gnupg/gpg-agent.conf
echo "pinentry-program /usr/bin/pinentry-gtk-2" >> ~/.gnupg/gpg-agent.conf
echo "allow-preset-passphrase" >> ~/.gnupg/gpg-agent.conf
```

### 2. Restart the gpg-agent

To restart the gpg-agent, run the following command:

```bash
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

### 3. Sign a commit

To sign a commit, run the following command:

```bash
git commit -S -m "Your commit message"
```

### 4. Verify the signature

To verify the signature of a commit, run the following command:

```bash
git verify-commit HEAD
```

### 5. Configure Visual Studio Code to use GPG

To configure Visual Studio Code to use GPG, open the settings by pressing `Ctrl + ,` and search for `git.enableCommitSigning`. Set the value to `true`.

### 6. Sign a commit

Make a commit in Visual Studio Code, and you will see a prompt asking you introduce your GPG passphrase. Enter your passphrase, and the commit will be signed.



That's it! Now you know how to sign Git commits in Visual Studio Code.












To configure Visual Studio Code to use GPG, open the settings by pressing `Ctrl + ,` and search for `git.signingKey`. Set the value to your GPG key ID.

### 7. Sign a commit

To sign a commit, run the following command:

```bash

git commit -S -m "Your commit message"
```

### 8. Verify the signature

To verify the signature of a commit, run the following command:

```bash

git verify-commit HEAD
```

That's it! Now you know how to sign Git commits in Visual Studio Code.

## Conclusion

In this post, we saw how to sign Git commits in Visual Studio Code. This is useful if you want to verify the authenticity of your commits. I hope you found this post helpful. If you have any questions or comments, please let me know. Thank you for reading!
```





