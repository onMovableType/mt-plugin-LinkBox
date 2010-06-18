#!/usr/bin/perl

package MT::Plugin::LinkBox;

use strict;
use base qw(MT::Plugin);
use MT;
use LinkBox;

use lib 'lib';

use vars qw( $VERSION );
$VERSION = '1.49';

my $plugin = MT::Plugin::LinkBox->new(
    {   id          => 'LinkBox',
        name        => 'LinkBox',
        version     => $VERSION,
        author_name => "Apperceptive, LLC",
        author_link => "http://www.apperceptive.com/",
        description => "Inserts blogroll-style linkbox into templates.",
        blog_config_template => 'blog_config.tmpl',
        settings             => MT::PluginSettings->new(
            [   [ 'liststyle', { Default => 'ul',    Scope => 'blog' } ],
                [ 'sortorder', { Default => 'added', Scope => 'blog' } ]
            ]
        ),
        schema_version => '0.42',
    }
);

MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    $plugin->registry(
        {   callbacks => {
                'cms_post_save.linkbox_list' =>
                    '$LinkBox::LinkBox::post_save_list',
            },
            object_types => {
                'linkbox_link' => 'LinkBox::Link',
                'linkbox_list' => 'LinkBox::LinkList',
            },
            applications => {
                cms => {
                    methods => {

                        # Two items we're adding to the menus
                        linkbox_list => '$LinkBox::LinkBox::list',

                        # Page action to create widget
                        linkbox_widget => '$LinkBox::LinkBox::widget',

                        # List management methods
                        linkbox_save => '$LinkBox::LinkBox::save',
                        linkbox_del  => '$LinkBox::LinkBox::del',

                        list_linkbox_list => '$LinkBox::LinkBox::list_lists',
                        view_linkbox_list =>
                            '$LinkBox::LinkBox::view_linkbox_list',
                    },
                    page_actions => {
                        list_templates => {
                            'linkbox_create_widget' => {
                                label      => 'Create a LinkBox Widget',
                                mode       => 'linkbox_widget',
                                permission => 'edit_templates',
                            },
                        },
                    },
                    menus => {
                        'manage:linkbox_lists' => {
                            label      => 'Link Lists',
                            mode       => 'list_linkbox_list',
                            order      => '5000',
                            view       => 'blog',
                            permission => 'publish_post',
                        },

                        # 'manage:linkbox_blogroll_config' => {
                        #   label => 'Edit Blogroll',
                        #   mode => 'linkbox_list',
                        #   order => 50001,
                        #   view => 'blog',
                        #   permission => 'publish_post'
                        # }, # close manage:linkbox_blogroll_config
                        }    # close menus
                },    # close cms
            },    # close applications
            tags => {
                function => {
                    'LinkBox'         => \&_hdlr_linkbox,
                    'LinkBoxLinkURL'  => \&_hdlr_linkbox_link_url,
                    'LinkBoxLinkName' => \&_hdlr_linkbox_link_name,
                    'LinkBoxLinkDescription' =>
                        \&_hdlr_linkbox_link_description,

                    'LinkBoxName' => \&_hdlr_link_box_name,
                },    # close function
                block => {
                    'LinkBoxLinks' => \&_hdlr_linkbox_iterator,
                    'LinkBoxes'    => \&_hdlr_link_boxes,
                },    # close block
                }    # close tags
        }
    );               # close plugin->registry call
}    # close &init_registry

sub instance { $plugin; }

sub _hdlr_linkbox {
    my ( $ctx, $args, $cond ) = @_;
    my $blog_id = $ctx->stash("blog_id");

    my $name = $args->{name};
    my ( %terms, %args );
    $terms{blog_id} = $blog_id;
    $terms{name} = $name if ($name);

    # in case name isn't specified, just grab the latest one
    $args{sort}      = 'modified_on';
    $args{direction} = 'descend';
    $args{limit}     = 1;

    my $list = LinkBox::LinkList->load( \%terms, \%args );
    return $ctx->error("Unable to find linkbox list") unless ($list);
    my @links = $list->links;

    #get settings
    my $settings = MT::Plugin::LinkBox->instance->get_config_hash(
        'blog:' . $blog_id );
    my $liststyle = $args->{list_style} || $settings->{liststyle};
    my $sortorder = $args->{sort_order} || $settings->{sortorder};

    my $out = "";

    if ( $sortorder && $sortorder eq "alpha" ) {
        @links = sort { $a->name cmp $b->name } @links;
    }
    $out = "<$liststyle class=\"linkbox\">\n";
    for my $l (@links) {
        $out
            .= "<li><a href=\"" . $l->link . "\">" . $l->name . "</a></li>\n";
    }
    $out .= "</$liststyle>\n";

    return $out;
}

sub _hdlr_linkbox_iterator {
    my ( $ctx, $args, $cond ) = @_;
    my $blog_id = $ctx->stash("blog_id");
    my $list;

    unless ( $list = $ctx->stash('linkbox_list') ) {
        my $name = $args->{name};
        my ( %terms, %args );
        $terms{blog_id} = $blog_id;
        $terms{name} = $name if ($name);

        # in case name isn't specified, just grab the latest one
        $args{sort}      = 'modified_on';
        $args{direction} = 'descend';
        $args{limit}     = 1;

        $list = LinkBox::LinkList->load( \%terms, \%args );
    }

    return $ctx->error("Unable to find linkbox list") unless ($list);
    my @links    = $list->links;
    my $settings = MT::Plugin::LinkBox->instance->get_config_hash(
        'blog:' . $blog_id );
    my $sortorder = $args->{sort_order} || $settings->{sortorder};

    if ( $sortorder && $sortorder eq "alpha" ) {
        @links = sort { $a->name cmp $b->name } @links;
    }
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $out     = "";
    for my $l (@links) {
        local $ctx->{__stash}{linkbox_link_id}          = $l->id;
        local $ctx->{__stash}{linkbox_link_name}        = $l->name;
        local $ctx->{__stash}{linkbox_link_link}        = $l->link;
        local $ctx->{__stash}{linkbox_link_description} = $l->description;

        $out .= $builder->build( $ctx, $tokens, $cond );
    }
    return $out;
}

sub _hdlr_linkbox_link_url {
    return $_[0]->stash('linkbox_link_link');
}

sub _hdlr_linkbox_link_name {
    return $_[0]->stash('linkbox_link_name');
}

sub _hdlr_linkbox_link_description {
    return $_[0]->stash('linkbox_link_description');
}

sub _hdlr_link_boxes {
    my ( $ctx, $args, $cond ) = @_;

    my $blog_id = $ctx->stash('blog_id');

    my $linkbox_id = $args->{id} if $args->{id};
    my $linkbox_name = $args->{name} if $args->{name};

    my @lists;
    require LinkBox::LinkList;

    if ($linkbox_id) {
        @lists = LinkBox::LinkList->load ({ id => $linkbox_id });
    } elsif ($linkbox_name) {
        @lists = LinkBox::LinkList->load ({ name => $linkbox_name });
    } else {
        @lists = LinkBox::LinkList->load( { blog_id => $blog_id },
                { sort => 'name', direction => 'ascend' } );
    }    

    my $res = '';
    for my $list (@lists) {
        local $ctx->{__stash}{linkbox_list}      = $list;
        local $ctx->{__stash}{linkbox_list_name} = $list->name;

        defined( my $out = $ctx->slurp( $args, $cond ) )
            or return $ctx->error( $ctx->errstr );
        $res .= $out;
    }

    $res;
}

sub _hdlr_link_box_name {
    return $_[0]->stash('linkbox_list_name');
}

1;
