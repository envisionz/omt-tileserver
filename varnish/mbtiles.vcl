# VCL script for varnish 4

vcl 4.0;

import std;

backend default {
  .host = "{{tileserver_host}}";
  .port = "{{tileserver_port}}";
  .probe = {
    .url = "/health";
    .timeout = 1s;
    .interval = 5s;
    .window = 5;
    .threshold = 3;
  }
}

sub vcl_recv {
  unset req.http.cookie;

  // Cache tiles and static images
  if (req.url ~ "{{tile_regex}}") {
    return (hash);
  } elseif(req.url ~ "{{static_regex}}") {
    return (hash);
  } else {
    return (pass);
  }
}

sub vcl_backend_response {
  // Remove all cookies
  unset beresp.http.set-cookie;
  unset beresp.http.cookie;

  set beresp.grace = 2m;
  set beresp.keep = 8m;

  // set cache key based on tile coordinate, so all variants can be purged at once
  // Also, provide minimal caching for high zoom levels
  if (bereq.url ~ "{{tile_regex}}") {
    set beresp.ttl = 4w;
  } elseif (bereq.url ~ "{{static_regex}}") {
    set beresp.ttl = 4w;
  }
}

sub vcl_hash {
  // Cache using only path as a hash.  
  // This means if a.tile/1/1/1/tile.png is accessed, b.tile/1/1/1/tile.png will also be fetch from cache
  // Note, don't hash quey params for tiles
  if (req.url ~ "{{tile_regex}}") {
    hash_data(regsub(req.url, "^(.+{{tile_regex}}).*$", "\1"));
  } else {
    hash_data(req.url);
  }
  return (lookup);
}
