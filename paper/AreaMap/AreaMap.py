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
        central_longitude=-145, central_latitude=60, standard_parallels=(55, 65)
    )

    # Create a Stamen terrain background instance.
    stamen_terrain = cimgt.Stamen("terrain-background")

    # sub_ax = plt.axes([0.705, 0.6075, 0.25, 0.25], projection=stamen_terrain.crs)
    sub_ax = plt.axes([0.585, 0.575, 0.3, 0.3], projection=AEA)

    sub_ax.set_extent([-170, -130, 55, 70], ccrs.Geodetic())

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
        xytext=(-3e5, -3e5),
        textcoords="data",
        bbox=bbox_props,
        arrowprops=arrow_props,
        size=5,
        zorder=4,
    )
    sub_ax.annotate(
        "Alaska",
        xy=(-5e5, 3.5e5),
        textcoords="data",
        bbox=bbox_props,
        size=5,
        zorder=4,
    )
    sub_ax.annotate(
        "Yukon",
        xy=(3e5, 3.5e5),
        textcoords="data",
        bbox=bbox_props,
        size=5,
        zorder=4,
    )
    sub_ax.annotate(
        "BC",
        xy=(7.25e5, -1e5),
        textcoords="data",
        bbox=bbox_props,
        size=5,
        zorder=4,
    )

################################################################################
# Filepath decleration
################################################################################
FL_dir = "/Users/andrewnolan/sfuvault/LilKluane/flowlines/"
FL_fp  = os.path.join(FL_dir, "manual/surge_trib/surge_trib.shp")
FL2_fp = os.path.join(FL_dir, "manual/main/Little_Kluan_FL_main.shp")
AOI_fn = "/Users/andrewnolan/sfuvault/LilKluane/AOI/AOI.shp"

Baseimg_fn = "./S2_baseim_29_08_2018.tif"
PreGLIMS_fn = "/Users/andrewnolan/sfuvault/LilKluane/GLIMS/Lil_Kluane/pre_surge/LilKluane_PreSurge.shp"
PostGLIMS_fn = "/Users/andrewnolan/sfuvault/LilKluane/GLIMS/Lil_Kluane/post_surge/LilKluane_postsurge.shp"
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

flowline = gpd.read_file(FL_fp)
# flowline2 = gpd.read_file(FL2_fp)

ticks = to_points(flowline.loc[0, "geometry"], 10.0)  # 10 m
ticks["x"] = ticks.index.to_numpy() * 10
ticks.crs = crs.proj4_init

PreGLIMS = gpd.read_file(PreGLIMS_fn)
PostGLIMS = gpd.read_file(PostGLIMS_fn)


################################################################################
# FIGURE
################################################################################
fig = plt.figure(figsize=(5, 5))
ax  = plt.subplot(111, projection=crs)

# Plot the base image
ax.imshow(base_img.transpose([1, 2, 0]), transform=crs, origin="upper", extent=imext)
# Plot the (glims and flowline) shapefiles
ax.add_geometries( PreGLIMS.geometry,  facecolor="none", crs=crs, edgecolor="#e7298a", linewidth=1.0)
ax.add_geometries( PostGLIMS.geometry, facecolor="none", crs=crs, edgecolor="#d95f02", linewidth=1.0)
ax.add_geometries( flowline.geometry,  facecolor="none", crs=crs, edgecolor="k",       linewidth=1.0)

ticks.loc[ticks["x"] % 1000 == 0, "geometry"].plot( ax=ax, markersize=4, marker="x", zorder=4, color="k" )

################################################################################
# Legend
################################################################################
patches = []
patches.append(mpatches.Patch(edgecolor="#e7298a", facecolor="none", label="Pre-Surge" ))
patches.append(mpatches.Patch(edgecolor="#d95f02", facecolor="none", label="Post-Surge"))
patches.append(Line2D([0], [0], color="k", label="Flowline"))
ax.legend(handles=patches, loc="upper left", ncol=1, framealpha=1, edgecolor="black", labelspacing=0 )  # , fontsize = 'large'
################################################################################

################################################################################
# Axis formating
################################################################################
# Set the axis limits
ax.set_ylim(6.748e6, 6.765e6)
ax.set_xlim(5.700e5, 589280.0)

ax.tick_params("y", rotation=300)
ax.ticklabel_format(style="sci", scilimits=(-3, 4), axis="both")

ax.yaxis.tick_right()
ax.xaxis.set_visible(True)
ax.yaxis.set_visible(True)
ax.yaxis.set_label_position("right")

ax.set_xlabel("Easting (m)")
ax.set_ylabel("Northing (m)", rotation=270, labelpad=15)
################################################################################

################################################################################
# Inset Map
################################################################################
inset_map()
################################################################################

# plt.show()
plt.savefig('geom_main_trib.eps',bbox_inches='tight', pad_inches=0.1, dpi=400)
plt.close()
