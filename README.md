# Localize-repo
Automatically localize antiX, Debian,  Mepis, and MX repo based on timezone

## How to add a mirror

As and example, let's add a mirror in France with the URLs:

    http://fr.mirror.vinzv.de/mxlinux/packages/antix
    http://fr.mirror.vinzv.de/mxlinux/packages/mepiscr
    http://fr.mirror.vinzv.de/mxlinux/packages/mx

Here is what you do:

1. Choose a two-letter abbreviation for this mirror.  In this
   case we will use "fr".

2. Add the abbreviation to the `MIRROR_PREFIXES` list in `localize_repo`

    ```
    MIRROR_PREFIXES="ec fr gr la nl nz ut tw"
    ```

3. Add the three URLs to `localize-repo` using "fr" as a prefix for
   the variable names and add the country or location:

    ```
    fr_AX_HOST=http://fr.mirror.vinzv.de/mxlinux/packages/antix
    fr_MP_HOST=http://fr.mirror.vinzv.de/mxlinux/packages/mepiscr
    fr_MX_HOST=http://fr.mirror.vinzv.de/mxlinux/packages/mx
    fr_LOCATION="France"
    ```

4. Add the mirror to the `MX_TZ` hash in `nearest-mx-mirror.pl`.
   You need to select a "timezone" city.  They are all listed in
   the zone.tab file.

    ```
    FR => "Europe/Paris",
    ```

    Note that we used uppercase for the abbreviation here.

5. Run `nearest-mx-mirror.pl` and collect the output.  The output
   will be a big case statement that will go into the
   `localize-repo` script, replacing the one that is already
   there:

    ```
    ./nearest-mx-mirror-pl > case-code
    ```
    NOTE: the `nearest-mx-mirror.pl` script requires the
    `Math::Trig` Perl module.

6. Replace the big case statement in localize-repo with the
   output you collected from `nearest-mx-repo.pl`

7.  Check to make sure it is doing what you expect.  For example
    try running:

    ```
    ./localize-repo --hosts --pretend fr
    ```

Make sure the URLs are what you expect.  Try to visit the URLs in
a browser and make sure they are valid.
