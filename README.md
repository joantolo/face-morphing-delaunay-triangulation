# Face morphing using Delaunay triangulation

<p> Here you can see how I implemented a face morphing method. </p>

<p> Briefly summarizing: </p>

* Having two images.
* Apply Delaunay triangulation to both.
* From one image to the other interpolate its triangles obtaining intermediate triangles.
* Obtain affine transformations from these intermediate triangles.
* Apply backward warping with these affine transformations to know the color of intermediate pixels.
* Finally blend intermediate images to obtain a morphing effect.
