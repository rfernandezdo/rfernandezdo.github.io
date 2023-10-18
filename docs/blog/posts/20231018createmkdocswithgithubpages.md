---
date: 2023-10-18
authors:
  - rfernandezdo
categories:
  - mkdocs
tags:  
  - DevOps  
---

# Create a blog with MkDocs,mkdocs-material, mkdocs-rss-plugin and GitHub Pages

A few time ago I maintained a blog with Wordpress. I was happy with it, but I wanted to try something new. 

I tried Jekyll but it didn't convince me, I discovered mkdocs so I decided to use [MkDocs](https://www.mkdocs.org/) and [mkdocs-material](https://squidfunk.github.io/mkdocs-material/). I was happy with the result, so I decided to write this post to explain how to create a blog with MkDocs, mkdocs-material and some plugins.

These is the first post of a serie of posts to create a blog with MkDocs, mkdocs-material and GitHub Pages and some customization.

Some knowledge:

- MkDocs is a fast, simple and downright gorgeous static site generator that's geared towards building project documentation. Documentation source files are written in Markdown, and configured with a single YAML configuration file.

- Material for MkDocs is a theme for MkDocs, a static site generator geared towards (technical) project documentation. It is built using Google's Material Design guidelines. Material for MkDocs provides a polished and responsive experience out of the box, and it is as easy to use for the beginner as it is for the seasoned developer.

- GitHub Pages is a static site hosting service that takes HTML, CSS, and JavaScript files straight from a repository on GitHub, optionally runs the files through a build process, and publishes a website. You can see more information about GitHub Pages [here](https://pages.github.com/).

- This plugin generates an RSS feed for your MkDocs site. You can see more information about mkdocs-rss-plugin [here](https://guts.github.io/mkdocs-rss-plugin/).


## Steps to deploy 

### Create a new repository

Create a new repository on GitHub named `username.github.io`, where `username` is your username (or organization name) on GitHub. If the first part of the repository doesn’t exactly match your username, it won’t work, so make sure to get it right.

### Enable GitHub Pages on your repository

Go into the repository settings and, if you are not using GitHub Pages already, enable GitHub Pages on the `gh-pages` branch.


### Clone the repository

Go to the folder where you want to store your project, and clone the new repository:

```bash
git clone ssh://github.com/username/username.github.io
cd username.github.io
```

### Create requirements.txt in root folder and install mkdocs, mkdocs-material and plugins

```bash
mkdocs==1.5.3
mkdocs-material==9.4.6
mkdocs-rss-plugin==1.8.0
```	

### Create a Python Virtual Environment and install requirements.txt
  
  ```bash
  python3 -m venv mysite
  source mysite/bin/activate
  pip install -r requirements.txt
  ```

### Initialize your site

```bash
mkdocs new .
```


### Add configuration to mkdocs.yml in root folder

For this post I am going to add the following configuration:

- basic configuration
- configuration for theme mkdocs-material
- some plugins og mkdocs-material

```bash
site_name: My Site 
site_description: A blog about Azure, DevOps and other stuff
site_author: Rafael Fernández

theme: 
  name: material
  features:
    - navigation.tabs
    - navigation.expand
    - navigation.sections
    - toc.integrate
    - toc.nested
    - toc.smoothscroll
    - footer

plugins:
  - search  
  - blog
  - tags:
      tags_file: tags.md      
    
  - rss:
      match_path: blog/posts/.* 
      date_from_meta:
        as_creation: date
      categories:
        - categories
        - tags
```

### publish your site

```bash
mkdocs gh-deploy
```




## urls
- [https://www.mkdocs.org/](https://www.mkdocs.org/)
- [https://pages.github.com/](https://pages.github.com/)
- [https://squidfunk.github.io/mkdocs-material/setup/setting-up-a-blog/](https://squidfunk.github.io/mkdocs-material/setup/setting-up-a-blog/)
- [https://guts.github.io/mkdocs-rss-plugin/](https://guts.github.io/mkdocs-rss-plugin/)
...
