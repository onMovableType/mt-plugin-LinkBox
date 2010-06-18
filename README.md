# LinkBox, a plugin for Movable Type

Authors: Six Apart, Ltd.  
Copyright: 2009 Six Apart, Ltd.  
License: [Artistic License 2.0](http://www.opensource.org/licenses/artistic-license-2.0.php)


## Overview

Manage and publish multiple blogrolls (lists of  links).


## Requirements

* MT 4.x


## Features

* Create and Manage LinkBoxes
* Add links with label for each to LinkBox
* Plugin preferences for:
    * list style: "ul" or "ol"
    * link list sort order: order added or alphabetical
* Tags to output LinkBoxes


## Documentation

### Container Tags

* `mt:LinkBoxes` - Loops over linkboxes for the blog and name provided

    Attributes:
    
    * `id` - optional id of a single LinkBox
    * `name` - optional name of a single LinkBox

* `mt:LinkBoxLinks` - Loops over links for the linkbox in context

### Function Tags

* `mt:LinkBox` - Returns a single linkbox specified by name (or it grabs the latest one) as a html list.

    Attributes:
    
    * `blog_id` - optional blog id
    * `name` - optional name of list
    * `list_style` - "ul" (default) or "ol" (can be specified in plugin settings as well)
    * `sort_order` - "added" (default) or "alpha" (can be specified in plugin settings as well)

* `mt:LinkBoxDescription` - description for the linkbox in context
* `mt:LinkBoxName` - name for the linkbox in context
* `mt:LinkBoxLinkURL` - URL for the link in context
* `mt:LinkBoxLinkName` - name for the link in context
* `mt:LinkBoxLinkDescription` - description for the link in context

### Examples

#### All LinkBoxs

    <mt:LinkBoxes>
        <div class="linkbox-container">
            <h3><$mt:LinkBoxName encode_html="1"$></h3>
            <ul class="linkbox">
        <mt:LinkBoxLinks>
                <li>
            <mt:If tag="MTLinkBoxLinkURL">
                        <a href="<mt:LinkBoxLinkURL encode_html="1">"><$mt:LinkBoxLinkName encode_html="1"$></a>
            <mt:Else>
                        <$mt:LinkBoxLinkName encode_html="1"$>
            </mt:If>
            <mt:If tag="MTLinkBoxLinkDescription">
                        <span><$mt:LinkBoxLinkDescription encode_html="1"$></span>
            </mt:If>
                </li>
        </mt:LinkBoxLinks>
            </ul>
        </div>
    </mt:LinkBoxes>

#### Specific LinkBox

    <$mt:Var name="linkbox_label" value="Favorite Sites"$>
    <div class="linkbox-container">
        <h3><$mt:Var name="linkbox_label"$></h3>
        <$mt:LinkBox name="$linkbox_label"$>
    </div>


## Installation

1. Move the LinkBox plugin directory to the MT `plugins` directory.
2. Move the LinkBox mt-static directory to the `mt-static/plugins` directory.

Should look like this when installed:

    $MT_HOME/
        plugins/
            LinkBox/
        mt-static/
            plugins/
                LinkBox/

[More in-depth plugin installation instructions](http://tinyurl.com/easy-plugin-install).


## Desired Features

* add further `mt:LinkBox` attributes to `mt:LinkBoxes` tag


## Support

This plugin is not an official Six Apart, Ltd. release, and as such support from Six Apart, Ltd. for this plugin is not available.
