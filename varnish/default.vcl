# VCL script for varnish 4

vcl 4.0;

backend tileserver {
  .host = "tileserver";
  .port = "8080";
}

sub vcl_recv {

  unset req.http.cookie;

  // Cache only tiles
  if (req.url ~ "/styles/[0-9a-zA-Z_\-]+/[0-9]+/[0-9]+/[0-9]+") {
    return (hash);
  } else {
    return (pass);
  }
}

sub vcl_backend_response {
  set beresp.ttl = 1h;

  // Remove all cookies
  unset beresp.http.set-cookie;
  unset beresp.http.cookie;

}

sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache_v = "HIT";
  } else {
    set resp.http.X-Cache_v = "MISS";
  }
}

sub vcl_hash {
  // Cache using only url as a hash.  
  // This means if a.tile/1/1/1/tile.png is accessed, b.tile/1/1/1/tile.png will also be fetch from cache
  hash_data(req.url);
  return (lookup);
}