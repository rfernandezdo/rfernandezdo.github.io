---
draft: false
date: 2024-04-30
authors:
  - rfernandezdo
categories:
    - DevOps
tags:
    - git
---
# Repository Strategy: Branching Strategy

Once we have decided that we will use branches, it is time to define a strategy, so that all developers can work in a coordinated way.

Some of the best known strategies are:

- **Gitflow**: It is a branching model designed around the project release. It is a strict branching model that assigns very specific roles to different branches.
- **Feature Branch**: It is a strategy where each feature is developed in a separate branch. This strategy is simple and easy to understand.
- **Trunk-Based Development**: It is a strategy where all developers work on a single branch. This strategy is simple and easy to understand.
- **GitHub Flow**: It is a strategy where all developers work on a single branch. This strategy is simple and easy to understand.
- **GitLab Flow**: It is a strategy where all developers work on a single branch. This strategy is simple and easy to understand.
- **Microsoft Flow**: It is a strategy where all developers work on a single branch. This strategy is simple and easy to understand.


## Gitflow

Gitflow is a branching model designed around the project release. It is a strict branching model that assigns very specific roles to different branches.

The Gitflow strategy is based on the following branches:

- **main**: It is the main branch of the project. It contains the code that is in production.
- **develop**: It is the branch where the code is integrated before being released to production.

The Gitflow strategy is based on the following types of branches:

- **feature**: It is the branch where the code for a new feature is developed.
- **release**: It is the branch where the code is prepared for release.
- **hotfix**: It is the branch where the code is developed to fix a bug in production.

The Gitflow strategy is based on the following rules:

- **Feature branches are created from the develop branch**.
- **Feature branches are merged into the develop branch**.
- **Release branches are created from the develop branch**.
- **Release branches are merged into the main and develop branches**.
- **Hotfix branches are created from the main branch**.
- **Hotfix branches are merged into the main and develop branches**.

The Gitflow strategy is based on the following workflow:

1. **Developers create a feature branch from the develop branch**.
2. **Developers develop the code for the new feature in the feature branch**.
3. **Developers merge the feature branch into the develop branch**.
4. **Developers create a release branch from the develop branch**.
5. **Developers prepare the code for release in the release branch**.
6. **Developers merge the release branch into the main and develop branches**.
7. **Developers create a hotfix branch from the main branch**.
8. **Developers fix the bug in the hotfix branch**.
9. **Developers merge the hotfix branch into the main and develop branches**.

```mermaid
gitGraph:
options
{
    "nodeSpacing": 150,
    "nodeRadius": 10
}
end
commit
branch develop
checkout develop
commit
commit
branch feature_branch
checkout feature_branch
commit
commit
checkout develop
merge feature_branch
commit
branch release_branch
checkout release_branch
commit
commit
checkout develop
merge release_branch
checkout main
merge release_branch
commit
branch hotfix_branch
checkout hotfix_branch
commit
commit
checkout develop
merge hotfix_branch
checkout main
merge hotfix_branch
```

The Gitflow strategy have the following advantages:

- **Isolation**: Each feature is developed in a separate branch, isolating it from other features.
- **Collaboration**: Developers can work on different features at the same time without affecting each other.
- **Stability**: The main branch contains the code that is in production, ensuring that it is stable and reliable.

The Gitflow strategy is based on the following disadvantages:

- **Complexity**: The Gitflow strategy is complex and can be difficult to understand for new developers.
- **Overhead**: The Gitflow strategy requires developers to create and manage multiple branches, which can be time-consuming.




## Feature Branch Workflow

Feature Branch is a strategy where each feature is developed in a separate branch. This strategy is simple and easy to understand.

The Feature Branch strategy is based on the following rules:

- **Developers create a feature branch from the main branch**.
- **Developers develop the code for the new feature in the feature branch**.
- **Developers merge the feature branch into the main branch**.

The Feature Branch strategy is based on the following workflow:

1. **Developers create a feature branch from the main branch**.
2. **Developers develop the code for the new feature in the feature branch**.
3. **Developers merge the feature branch into the main branch**.

```mermaid
gitGraph:
options
{
    "nodeSpacing": 150,
    "nodeRadius": 10
}
end
commit
checkout main
commit
commit
branch feature_branch
checkout feature_branch
commit
commit
checkout main
merge feature_branch
```

The Feature Branch strategy is based on the following advantages:

- **Simplicity**: The Feature Branch strategy is simple and easy to understand.
- **Flexibility**: Developers can work on different features at the same time without affecting each other.
- **Visibility**: Changes made in feature branches are visible to other developers, making it easier to review and merge changes.

The Feature Branch strategy is based on the following disadvantages:

- **Conflicts**: Multiple developers working on the same feature can lead to conflicts and merge issues.
- **Complexity**: Managing multiple feature branches can be challenging, especially in large projects.

## Trunk-Based Development

The Trunk-Based Development strategy is based on the following rules:

- **Developers work on a single branch**.
- **Developers create feature flags to hide unfinished features**.
- **Developers merge the code into the main branch when it is ready**.

The Trunk-Based Development strategy is based on the following workflow:

1. **Developers work on a single branch**.
2. **Developers create feature flags to hide unfinished features**.
3. **Developers merge the code into the main branch when it is ready**.

```mermaid
gitGraph:
options
{
    "nodeSpacing": 150,
    "nodeRadius": 10
}
end
commit
checkout main
commit
commit tag:"v1.0.0"
commit
commit
commit tag:"v2.0.0"
```

The Trunk-Based Development strategy is based on the following advantages:

- **Simplicity**: The Trunk-Based Development strategy is simple and easy to understand.
- **Flexibility**: Developers can work on different features at the same time without affecting each other.
- **Visibility**: Changes made in the main branch are visible to other developers, making it easier to review and merge changes.


The Trunk-Based Development strategy is based on the following disadvantages:

- **Conflicts**: Multiple developers working on the same codebase can lead to conflicts and merge issues.
- **Complexity**: Managing feature flags can be challenging, especially in large projects.

## GitHub Flow

GitHub Flow is a strategy where all developers work on a single branch. This strategy is simple and easy to understand.

The GitHub Flow strategy is based on the following rules:

- **Developers work on a single branch**.
- **Developers create feature branches to work on new features**.
- **Developers merge the feature branches into the main branch when they are ready**.

The GitHub Flow strategy is based on the following workflow:

1. **Developers work on a single branch**.
2. **Developers create a feature branch from the main branch**.
3. **Developers develop the code for the new feature in the feature branch**.
4. **Developers merge the feature branch into the main branch**.

```mermaid
gitGraph:
options
{
    "nodeSpacing": 150,
    "nodeRadius": 10
}
end
commit
checkout main
commit
commit
branch feature_branch
checkout feature_branch
commit
commit
checkout main
merge feature_branch
```

## GitLab Flow

GitLab Flow is a strategy where all developers work on a single branch. This strategy is simple and easy to understand. GitLab Flow is often used with release branches.



The GitLab Flow strategy is based on the following rules:

- **Developers work on a single branch**.
- **Developers create feature branches to work on new features**.
- **Developers merge the feature branches into the main branch when they are ready**.
- **Developers create a pre-production branch to make bug fixes before merging changes back to the main branch**.
- **Developers merge the pre-production branch into the main branch before going to production**.
- **Developers can add as many pre-production branches as needed**.
- **Developers can maintain different versions of the production branch**.



The GitLab Flow strategy is based on the following workflow:

1. **Developers work on a single branch**.
2. **Developers create a feature branch from the main branch**.
3. **Developers develop the code for the new feature in the feature branch**.
4. **Developers merge the feature branch into the main branch**.
5. **Developers create a pre-production branch from the main branch**.
6. **Developers make bug fixes in the pre-production branch**.
7. **Developers merge the pre-production branch into the main branch**.
8. **Developers create a production branch from the main branch**.
9. **Developers merge the production branch into the main branch**.

```mermaid
gitGraph:
options
{
    "nodeSpacing": 150,
    "nodeRadius": 10
}
end
commit
checkout main
commit
commit
branch feature_branch
checkout feature_branch
commit
commit
checkout main
merge feature_branch
commit
branch pre-production
checkout pre-production
commit
commit
checkout main
merge pre-production
commit
branch production
checkout production
commit
commit
checkout main
merge production
```






