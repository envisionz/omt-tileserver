# VCL script for varnish 4

vcl 4.0;

import xkey;

backend tileserver {
  .host = "tileserver";
  .port = "8080";
}

backend postserve {
  .host = "postserve";
  .port = "8080";
}

acl purgers {
  "localhost";
}

sub vcl_recv {
  if (req.method == "PURGE") {
    if (client.ip !~ purgers) {
        return (synth(403, "Forbidden"));
    }
    if (req.http.xkey) {
		  #set req.http.n-gone = xkey.purge(req.http.xkey);
		  set req.http.n-gone = xkey.softpurge(req.http.xkey);
		  return (synth(200, "Invalidated "+req.http.n-gone+" objects"));
	  } else {
		  return (purge);
	  }
  }

  unset req.http.cookie;

  if (req.url ~ "/tiles/[0-9]+/[0-9]+/[0-9]+\.pbf") {
    set req.backend_hint = postserve;
  } else {
    set req.backend_hint = tileserver;
  }

  // Cache only tiles
  if (req.url ~ "/[0-9]+/[0-9]+/[0-9]+\.(webp|png|jpg|jpeg|pbf)") {
    return (hash);
  } else {
    return (pass);
  }
}

sub vcl_backend_response {
  set beresp.ttl = 4w;

  // Remove all cookies
  unset beresp.http.set-cookie;
  unset beresp.http.cookie;

  // set cache key based on tile coordinate, so all variants can be purged at once
  if (bereq.url ~ "/[0-9]+/[0-9]+/[0-9]+\.(webp|png|jpg|jpeg|pbf)") {
    set beresp.http.xkey = regsub(bereq.url, "^.+/([0-9]+/[0-9]+/[0-9]+)\.(webp|png|jpg|jpeg|pbf).*$", "\1");
  }
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