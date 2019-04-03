# gyrocam

Processing sketch for working with GoPro metadata (Hero5 and beyond), previously extracted using my GPMD2CSV tool https://tailorandwayne.com/gopro-telemetry-extractor/ (Source: https://github.com/JuanIrache/gopro-utils )

It was created specifically for this project: https://youtu.be/bg8B0Hl_au0 (Data+Stabilisation)

It can mostly work with IMU (accelerometer+gyroscope+gps) data, adapt it to the framerate and individual frames, print the data and stabilise the video, or output it to csv for use in After Effects.

Exported files:
- GXXX-AEgForce.csv: Total G-Force of a frame. Adds all 3 components (x,y,z). Usefull for showing the value or visualising with a slider or graph.
- GXXX-AElocations.csv: Longitude, Latitude and Altitude per frame. Usefull for showing the value or showing the location on a map.
- GXXX-AEposition.csv: X,Y movement for stabilising a video layer, in pixels.
- GXXX-AErotation.csv: Rotation for stabilising horizon tilt (z axis). Needs to be adapted with keyframes when rotating around another axis (more mathematical knowledge is needed to automate this. Anyone?)
- GXXX-AErpm.csv: Absolute rotation value in RPM. Can be shown as a value or graph. Combines all 3 axis.
- GXXX-AEvibr.csv: Shows accelerations in every axis. Can create a vibrating graph.
- GXXX-AEvibrhz.csv: Measures vibrations per second, Hz. Can be shown as value, graph...
- GXXX-latlong.svg: SVG map of locations. You can open it in Illustrator to simplify it, save as .ai, import in After Effects and Create Shapes with Vector Layer. Then trim paths to see the progress.

ToDo:
- Export distance (covered/total), to show the data and trim paths of the map.
- Export speed.

This can certainly be improved, maybe turned into a library...

Once your data is exported to csv, open the file, copy the content and you can paste it to an After Effects layer.

Here are some other projects of mine that you might find interesting: http://tailorandwayne.com/coding-projects/
