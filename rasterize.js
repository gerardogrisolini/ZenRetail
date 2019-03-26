//  Takes a screenshot of a URL or HTML string. Optionally, set viewport size
//  and resolution, or capture only a specific element
//
//  Usage: `phantomjs rasterize.js URL|[or URI encoded HTML string] output size scale element`
//
//  Examples:
//    `phantomjs rasterize.js http://google.com google.png`
//    `phantomjs rasterize.js http://google.com img/google-logo.png auto 1 \#hplogo`
//    `phantomjs rasterize.js %3Chtml%3E%3Cbody%3E%3Ch1%3EHello%20world!%3C%2Fh1%3E%3C%2Fbody%3E%3C%2Fhtml%3E hello-world.png
//
//  Arguments:
//    URL or HTML: A URL or a URI encoded string of HTML
//    output:      The path and filename of the screenshot
//    size:        The nominal size of the viewport.
//                 If `scale` is passed, `size` will be multiplied by `scale`.
//                 This argument is ignored if `element` is passed.
//    scale:       The scaling factor.
//                 Use to simulate high-res, retina viewports.
//    element:     A specific DOM selector to capture.
//                 Clips the screenshot to the element.
//                 On the command line, be sure to escape ID selectors (`#id`)
//                 with a backslash (`\`), i.e.: `\#id`

/* globals require, phantom */

var page = require('webpage').create(),
    system = require('system'),
    args = system.args,
    urlOrHTML, outputFile, size, scale, element, preflight, pageWidth, pageHeight;

preflight = function () {
    var clipDimensions;

    if (scale) {
        page.evaluate(function (scale) {
            document.body.style.webkitTransform = "scale(" + scale + ")";
            document.body.style.webkitTransformOrigin = "0% 0%";
            document.body.style.width = (100 / scale) - 3.0 + "%";
            return;
        }, scale);
    }

    if (element) {
        clipDimensions = page.evaluate(function (element) {
            element = document.querySelector(element);

            if (!element) {
                console.log('Unable to load ' + element + ', exiting');
                return false;
            }

            return element.getBoundingClientRect();
        }, element);

        page.clipRect = clipDimensions;
    }
};

if (args.length < 3 || args.length > 6) {
    console.log('Usage: rasterize.js URL|HTML output size scale element');
    console.log('  size examples: "1920px", "800px*600px", "auto"');
    phantom.exit(1);
}

else {
    urlOrHTML = args[1]; //decodeURIComponent(args[1]);
    outputFile = args[2];
    size = args[3] !== null ? args[3].split('*') : [];
    scale = args[4];
    element = args[5];
    page.settings.loadImages = true;
    page.paperSize = size.length === 2
        ? {
            width: size[0],
            height: size[1],
            margin: '0cm'
        } : {
            format: 'A4',
            orientation: 'portrait',
            margin: '1cm'
        };
    page.viewportSize = { width: 800, height: 600 };

    if (size && size != 'auto') {
        // Width and height dimensions were passed in with X*Y format
        if (size.length === 2) {
            pageWidth = parseInt(size[0], 10);
            pageHeight = parseInt(size[1], 10);
            page.viewportSize = { width: pageWidth, height: pageHeight };
            page.clipRect = { top: 0, left: 0, width: pageWidth, height: pageHeight };
        }
        // Only width was passed
        else {
            pageWidth = parseInt(size, 10);
            pageHeight = parseInt(pageWidth * 3 / 4, 10); // it's as good an assumption as any
            page.viewportSize = { width: pageWidth, height: pageHeight };
        }
    }

    //  if (urlOrHTML.match('http')) {
    //      page.open(urlOrHTML, function (status) {
    //          if (status !== 'success') {
    //              console.log('Unable to load the URL!');
    //              phantom.exit(1);
    //          }

    //          else {
    //              window.setTimeout(function () {
    //                  preflight();
    //                  page.render(outputFile);
    //                  phantom.exit();
    //              }, 2000);
    //          }
    //      });
    //  }
    //  else {
        page.setContent(urlOrHTML, null);
        window.setTimeout(function () {
            preflight();
            page.render(outputFile);
            phantom.exit();
        }, 3000);
    //  }
}
