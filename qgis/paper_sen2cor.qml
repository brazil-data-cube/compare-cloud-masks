<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis maxScale="0" styleCategories="AllStyleCategories" minScale="1e+8" hasScaleBasedVisibilityFlag="0" version="3.4.14-Madeira">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>0</Searchable>
  </flags>
  <customproperties>
    <property key="WMSBackgroundLayer" value="false"/>
    <property key="WMSPublishDataSourceUrl" value="false"/>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="identify/format" value="Value"/>
  </customproperties>
  <pipe>
    <rasterrenderer type="paletted" alphaBand="-1" band="1" opacity="1">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <colorPalette>
        <paletteEntry color="#00ff00" alpha="255" label="0 NA - no data"                     value="0"/>
        <paletteEntry color="#00ff00" alpha="255" label="1 NA - saturated or defective"      value="1"/>
        <paletteEntry color="#b63ab2" alpha="255" label="3 shadow - cloud shadows"           value="3"/>
        <paletteEntry color="#b63ab2" alpha="255" label="2 shadow - dark area pixels"        value="2"/>
        <paletteEntry color="#000000" alpha="255" label="4 clear - vegetation"               value="4"/>
        <paletteEntry color="#000000" alpha="255" label="5 clear - bare soils"               value="5"/>
        <paletteEntry color="#000000" alpha="255" label="6 clear - water"                    value="6"/>
        <paletteEntry color="#00ff00" alpha="255" label="7 NA - unclassified"                value="7"/>
        <paletteEntry color="#ffffff" alpha="255" label="8 cloud - cloud medium probability" value="8"/>
        <paletteEntry color="#ffffff" alpha="255" label="9 cloud - cloud high probability"   value="9"/>
        <paletteEntry color="#ffffff" alpha="255" label="10 cirrus - thin cirrus"            value="10"/>
        <paletteEntry color="#000000" alpha="255" label="11 clear - snow"                    value="11"/>
      </colorPalette>
      <colorramp type="gradient" name="[source]">
        <prop k="color1" v="68,1,84,255"/>
        <prop k="color2" v="253,231,37,255"/>
        <prop k="discrete" v="0"/>
        <prop k="rampType" v="gradient"/>
        <prop k="stops" v="0.0196078;70,8,92,255:0.0392157;71,16,99,255:0.0588235;72,23,105,255:0.0784314;72,29,111,255:0.0980392;72,36,117,255:0.117647;71,42,122,255:0.137255;70,48,126,255:0.156863;69,55,129,255:0.176471;67,61,132,255:0.196078;65,66,135,255:0.215686;63,72,137,255:0.235294;61,78,138,255:0.254902;58,83,139,255:0.27451;56,89,140,255:0.294118;53,94,141,255:0.313725;51,99,141,255:0.333333;49,104,142,255:0.352941;46,109,142,255:0.372549;44,113,142,255:0.392157;42,118,142,255:0.411765;41,123,142,255:0.431373;39,128,142,255:0.45098;37,132,142,255:0.470588;35,137,142,255:0.490196;33,142,141,255:0.509804;32,146,140,255:0.529412;31,151,139,255:0.54902;30,156,137,255:0.568627;31,161,136,255:0.588235;33,165,133,255:0.607843;36,170,131,255:0.627451;40,174,128,255:0.647059;46,179,124,255:0.666667;53,183,121,255:0.686275;61,188,116,255:0.705882;70,192,111,255:0.72549;80,196,106,255:0.745098;90,200,100,255:0.764706;101,203,94,255:0.784314;112,207,87,255:0.803922;124,210,80,255:0.823529;137,213,72,255:0.843137;149,216,64,255:0.862745;162,218,55,255:0.882353;176,221,47,255:0.901961;189,223,38,255:0.921569;202,225,31,255:0.941176;216,226,25,255:0.960784;229,228,25,255:0.980392;241,229,29,255"/>
      </colorramp>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation saturation="0" colorizeOn="0" colorizeBlue="128" grayscaleMode="0" colorizeGreen="128" colorizeRed="255" colorizeStrength="100"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
