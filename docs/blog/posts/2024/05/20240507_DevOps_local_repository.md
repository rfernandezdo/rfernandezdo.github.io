---
draft: false
date: 2024-05-07
authors:
  - rfernandezdo
categories:
    - DevOps
tags:
    - git
---
# Repository Strategy: How to test Branching Strategy in local repository

If you don't want to test in github, gitlab, or azure devops, you can test in your local desktop.


## **Step 1: Create a new local bare repository**

To create a new local bare repository, open a terminal window and run the following command:

```pwsh
mkdir localrepo
cd localrepo
git init --bare my-repo.git
```

This command creates a new directory called `localrepo` and initializes a new bare repository called `my-repo.git` inside it.

## **Step 2: Create a local repository**

To create a new local repository, open a terminal window and run the following command:

```pwsh
mkdir my-repo
cd my-repo
git init
```

This command creates a new directory called `my-repo` and initializes a new repository inside it.

## **Step 3: Add the remote repository**

To add the remote repository to your local repository, run the following command:

```pwsh
git remote add origin ../my-repo.git
```

In mi case, I have used absolute path, c:\users\myuser\localrepo\my-repo.git:

```pwsh
git remote add origin c:\users\myuser\localrepo\my-repo.git
```

This command adds the remote repository as the `origin` remote.

## **Step 4: Create a new file, make first commit and push*

To create a new file in your local repository, run the following command:

```pwsh
echo "Hello, World!" > hello.txt
```

This command creates a new file called `hello.txt` with the content `Hello, World!`.

To make the first commit to your local repository, run the following command:

```pwsh
git add hello.txt
git commit -m "Initial commit"
```

This command stages the `hello.txt` file and commits it to the repository with the message `Initial commit`.

To push the changes to the remote repository, run the following command:

```pwsh
git push -u origin master
```

This command pushes the changes to the `master` branch of the remote repository.

## **Step 5: Create a new branch and push it to the remote repository**

To create a new branch in your local repository, run the following command:

```pwsh
git checkout -b feature-branch
```

This command creates a new branch called `feature-branch` and switches to it.

## Conclusion

By following these steps, you can test your branching strategy in a local repository before pushing changes to a remote repository. This allows you to experiment with different branching strategies and workflows without affecting your production codebase.










