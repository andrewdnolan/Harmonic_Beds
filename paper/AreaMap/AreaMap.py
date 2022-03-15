#!/usr/bin/env python

"""
    fig_01.py:
        - Little Kluane Area Map
"""

import os
import fiona
import cartopy
import rasterio
import numpy as np
import xarray as xr
import rasterio.mask
import shapely.geometry
import geopandas as gpd
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.lines import Line2D
import matplotlib.patches as mpatches

import cartopy.io.img_tiles as cimgt

plt.rc("text", usetex=True)

# set geopandas up to read .kml files
gpd.io.file.fiona.drvsupport.supported_drivers['KML'] = 'rw'

# https://stackoverflow.com/questions/34906124/interpolating-every-x-distance-along-multiline-in-shapely
def to_points(geom, dist):
    num_vert = int(round(geom.length / dist))
    points = [
        geom.interpolate(float(n) / num_vert, normalized=True)
        for n in range(num_vert + 1)
    ]
    return gpd.GeoDataFrame(geometry=points)

def inset_map():
    ################################################################################
    # Inset Map
    ################################################################################
    AOI_fn = "/Users/andrewnolan/sfuvault/LilKluane/AOI/AOI.shp"
    AOI = gpd.read_file(AOI_fn)

    AEA = ccrs.AlbersEqualArea(
        central_longitude=-145, central_latitude=62.5, standard_parallels=(55, 65)
    )

    # Create a Stamen terrain background instance.
    stamen_terrain = cimgt.Stamen("terrain-background")

    # sub_ax = plt.axes([0.585, 0.575, 0.3, 0.3], projection=AEA)
    sub_ax = plt.axes([0.45, 0.575, 0.3, 0.3], projection=AEA)
    sub_ax.set_extent([-150, -130, 55, 70], ccrs.Geodetic())

    grat  = cartopy.feature.NaturalEarthFeature(category="physical", scale="50m", name="graticules_5")
    land  = cartopy.feature.NaturalEarthFeature(category="physical", scale="50m", name="land")
    ocean = cartopy.feature.NaturalEarthFeature(category="physical", scale="50m", name="ocean")
    boarders = cartopy.feature.NaturalEarthFeature(category="cultural", scale="50m", name="BORDERS"
    )
    province = cartopy.feature.NaturalEarthFeature(
        category="cultural", scale="50m", name="admin_1_states_provinces_lines"
    )

    sub_ax.coastlines(resolution="50m", color="#000000", linewidth=0.5, zorder=2)
    sub_ax.add_feature(ocean, zorder=0, facecolor="#808080")
    sub_ax.add_feature(land, zorder=1, facecolor="#EEEEEE")

    # sub_ax.add_image(stamen_terrain, 6)
    sub_ax.add_feature(
        grat, linewidth=0.5, linestyle=":", edgecolor="#000000", facecolor="None", zorder=3
    )
    sub_ax.add_feature(
        cartopy.feature.BORDERS,
        linewidth=1.0,
        linestyle="-",
        edgecolor="#000000",
        facecolor="None",
        zorder=3,
    )
    sub_ax.add_feature(
        province, linestyle="-", linewidth=0.75, edgecolor="k", facecolor="None", zorder=10
    )

    bbox_props = dict(boxstyle="round4, pad=0.3", fc="white", ec="k", lw=0.5)
    arrow_props = dict(arrowstyle="->", connectionstyle="arc3")

    AOI = AOI.to_crs(AEA.proj4_init)
    sub_ax.add_geometries(AOI.geometry, crs=AEA, facecolor="r", edgecolor="r")

    sub_ax.annotate(
        "Study Area",
        xy=(AOI["geometry"][0].centroid.x, AOI["geometry"][0].centroid.y),
        xytext=(-2e5, -7e5),
        textcoords="data",
        bbox=bbox_props,
        arrowprops=arrow_props,
        size=8,
        zorder=4,
    )
    sub_ax.annotate(
        "AK",
        xy=(-2e5, 0.5e5),
        textcoords="data",
        bbox=bbox_props,
        size=8,
        zorder=4,
    )
    sub_ax.annotate(
        "Yukon",
        xy=(2.5e5, 0.5e5),
        transform=AEA,
        textcoords="data",
        bbox=bbox_props,
        size=8,
        zorder=4,
    )
    # sub_ax.annotate(
    #     "BC",
    #     xy=(7.25e5, -1e5),
    #     textcoords="data",
    #     bbox=bbox_props,
    #     size=5,
    #     zorder=4,
    # )

def scale_bar(ax, proj, length, location=(0.5, 0.05), linewidth=3):
    """
    http://stackoverflow.com/a/35705477/1072212
    ax is the axes to draw the scalebar on.
    proj is the projection the axes are in
    location is center of the scalebar in axis coordinates ie. 0.5 is the middle of the plot
    length is the length of the scalebar in km.
    linewidth is the thickness of the scalebar.
    units is the name of the unit
    m_per_unit is the number of meters in a unit
    """

    from matplotlib import patheffects

    units='km'
    m_per_unit=1000

    # Get the extent of the plotted area in coordinates in metres
    x0, x1, y0, y1 = ax.get_extent(proj)
    # Turn the specified scalebar location into coordinates in metres
    sbcx, sbcy = x0 + (x1 - x0) * location[0], y0 + (y1 - y0) * location[1]
    # Generate the x coordinate for the ends of the scalebar
    bar_xs = [sbcx - length * m_per_unit/2, sbcx + length * m_per_unit/2]
    # buffer for scalebar
    buffer = [patheffects.withStroke(linewidth=5, foreground="w")]
    # Plot the scalebar with buffer
    ax.plot(bar_xs, [sbcy, sbcy], transform=proj, color='k',
        linewidth=linewidth, path_effects=buffer)
    # buffer for text
    buffer = [patheffects.withStroke(linewidth=3, foreground="w")]
    # Plot the scalebar label
    t0 = ax.text(sbcx, sbcy, str(length) + ' ' + units, transform=proj,
        horizontalalignment='center', verticalalignment='bottom',
        path_effects=buffer, zorder=2, size=12)

    N_x = bar_xs[1] - length*m_per_unit*0.15
    N_y = sbcy      + length*m_per_unit*0.15

    plt.rc("text", usetex=False)
    # Plot the N arrow
    t1 = ax.text(N_x, N_y, u"\u25B2\nN", transform=proj,
        horizontalalignment='center', verticalalignment='bottom',
        path_effects=buffer, zorder=2, size=12)
    plt.rc("text", usetex=True)

    # Plot the scalebar without buffer, in case covered by text buffer
    ax.plot(bar_xs, [sbcy, sbcy], transform=proj, color='k',
        linewidth=linewidth, zorder=3)

################################################################################
# Filepath decleration
################################################################################
LK_dir = "/Users/andrewnolan/sfuvault/LilKluane"
FL_fp  = "./Data/flowlines/centerlines_postsurge.shp"
AOI_fn = os.path.join(LK_dir, "AOI/AOI.shp")

Baseimg_fn   = "./S2_baseim_29_08_2018.tif"
PreGLIMS_fn  = os.path.join(LK_dir, "GLIMS/Lil_Kluane/pre_surge/LilKluane_PreSurge.shp")
PostGLIMS_fn = os.path.join(LK_dir, "GLIMS/Lil_Kluane/post_surge/LilKluane_postsurge.shp")

GPR_2019_fp = "./Data/Radar/2019/lk_gpr.shp"
GPR_2021_fp = "./Data/Radar/2021/LK_18JUL2021_picked_line_*.nc"
################################################################################


with fiona.open(PreGLIMS_fn, "r") as shapefile:
    shapes = [feature["geometry"] for feature in shapefile]

with rasterio.open(Baseimg_fn) as src:
    crs = ccrs.epsg(src.crs["init"].split(":")[1])

    glacier_mask = rasterio.mask.raster_geometry_mask(
        src, shapes, crop=True, pad=True, pad_width=5000
    )
    mask_extent = rasterio.transform.array_bounds(
        *glacier_mask[0].shape, glacier_mask[1]
    )
    imext = [mask_extent[0], mask_extent[2], mask_extent[1], mask_extent[3]]

    sub_window = src.window(*mask_extent)
    base_img = src.read(window=sub_window)

    transform = rasterio.windows.transform(sub_window, src.transform)

flowline   = gpd.read_file(FL_fp)
flowline   = flowline.to_crs(crs.proj4_init)
ticks      = to_points(flowline.loc[0, "geometry"], 10.0)  # 10 m
ticks["x"] = ticks.index.to_numpy() * 10

PreGLIMS  = gpd.read_file(PreGLIMS_fn)
PostGLIMS = gpd.read_file(PostGLIMS_fn)

GPR_2019 = gpd.read_file(GPR_2019_fp)
GPR_2019 = GPR_2019.to_crs(epsg=32607)
GPR_2021 = xr.open_mfdataset(GPR_2021_fp, concat_dim='Line', combine="nested")

radar_lines = gpd.read_file('./Data/Radar/LittleKluane2021.kml', driver='KML')
radar_lines = radar_lines.to_crs(epsg=32607)

################################################################################
# FIGURE
################################################################################
fig = plt.figure(figsize=(6, 4))
ax  = plt.subplot(111, projection=crs)

# Plot the base image
ax.imshow(base_img.transpose([1, 2, 0]), transform=crs, origin="upper", extent=imext)
# Plot the (glims and flowline) shapefiles
ax.add_geometries( PreGLIMS.geometry,  facecolor="none", crs=crs, edgecolor="#e7298a", linewidth=1.0)
ax.add_geometries( PostGLIMS.geometry, facecolor="none", crs=crs, edgecolor="#7570b3", linewidth=1.0)
ax.add_geometries( flowline.geometry,  facecolor="none", crs=crs, edgecolor="k",       linewidth=1.0)
ticks.loc[ticks["x"] % 1000 == 0, "geometry"].plot( ax=ax, markersize=4, marker="x", zorder=4, color="k" )


# plot the radar lines from 2019
ax.scatter(GPR_2019.geometry.apply(lambda x: x.coords[0][0]),
           GPR_2019.geometry.apply(lambda x: x.coords[0][1]),
           color="#d95f02", s=5, zorder=6)

# plot the radar lines from 2021
for i in range(len(GPR_2021.Line)):

    ax.scatter(GPR_2021.isel(Line=i).Easting,
               GPR_2021.isel(Line=i).Northing,
               color="#d95f02", s=5, zorder=6)


################################################################################
# Legend
################################################################################
patches = []
patches.append(mpatches.Patch(edgecolor="#e7298a", facecolor="none", label="Pre-Surge" ))
patches.append(mpatches.Patch(edgecolor="#7570b3", facecolor="none", label="Post-Surge"))
patches.append(Line2D([0], [0], color="#d95f02", label="Radar data"))
patches.append(Line2D([0], [0], color="k", label="Flowline"))
ax.legend(handles=patches,
            loc="lower left",
            ncol=2,
            framealpha=1,
            edgecolor="black",
            labelspacing=0 )  # , fontsize = 'large'
################################################################################


################################################################################
# Axis formating
################################################################################
# Set the axis limits
ax.set_ylim(6.748e6, 6.761e6) #6.765e6
ax.set_xlim(5.700e5, 589280.0)

ax.tick_params("y", rotation=300)
ax.ticklabel_format(style="sci", scilimits=(-3, 4), axis="both")

# ax.yaxis.tick_right()
# ax.xaxis.set_visible(True)
# ax.yaxis.set_visible(True)
# ax.yaxis.set_label_position("right")

# ax.set_xlabel("Easting (m)")
# ax.set_ylabel("Northing (m)", rotation=270, labelpad=15)
################################################################################

################################################################################
# Inset Map
inset_map()
# Scale Bar
scale_bar(ax, crs, 5, location=(0.85, 0.05))
################################################################################

# plt.tight_layout()
# plt.show()
plt.savefig('geom_main_trib_test.pdf', bbox_inches='tight')
# plt.close()
