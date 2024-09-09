---
draft: false
date: 2024-09-09
authors:
  - rfernandezdo
categories:
    - DevOps

tags:
    - markmap
---

# markmap

markmap is a visualisation tool that allows you to create mindmaps from markdown files. It is based on the mermaid library and can be used to create a visual representation of a markdown file.

## Installation in mkdocs

To install markmap in mkdocs, you need install the plugin using pip:

```bash
pip install mkdocs-markmap
```

Then, you need to add the following lines to your `mkdocs.yml` file:

```yaml
plugins:
  - markmap
```

## Usage

To use markmap, you need to add the following code block to your markdown file:

````markdown
```markmap	
# Root

## Branch 1

* Branchlet 1a
* Branchlet 1b

## Branch 2

* Branchlet 2a
* Branchlet 2b
```
````

And this will generate the following mindmap:

![alt text](20240909_DevOps_markmap.png)

That is for the future, because in my mkdocs not work as expected:

```markmap
# Root

## Branch 1

* Branchlet 1a
* Branchlet 1b

## Branch 2

* Branchlet 2a
* Branchlet 2b
```

## Visual Studio Code Extension

There is also a Visual Studio Code extension that allows you to create mindmaps from markdown files. You can install it from the Visual Studio Code marketplace.

```text
    Name: Markdown Preview Markmap Support
    Id: phoihos.markdown-markmap
    Description: Visualize Markdown as Mindmap (A.K.A Markmap) to VS Code's built-in markdown preview
    Version: 1.4.6
    Publisher: phoihos
    VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=phoihos.markdown-markmap
```
[VS Marketplace Link](https://marketplace.visualstudio.com/items?itemName=phoihos.markdown-markmap)

## Conclusion

I don't like too much this plugin because it not work as expected in my mkdocs but it's a good tool for documentation.

## References

- [markmap](https://markmap.js.org/)
- [mkdocs-markmap](https://github.com/markmap/mkdocs-markmap)