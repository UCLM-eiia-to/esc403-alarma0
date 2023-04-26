<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                version='1.0'>

    <xsl:output method="text" encoding="UTF-8"/>
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

    <xsl:template match="/">
        <xsl:apply-templates select="entity[@class='ptolemy.domains.modal.kernel.FSMActor']" mode="FSM"/>
    </xsl:template>

    <xsl:template match="entity" mode="FSM">
        <xsl:variable name="fsm" select="@name"/>
        <xsl:variable name="states" select="entity[@class='ptolemy.domains.modal.kernel.State']" />
        <xsl:variable name="funcs" select="property[@class='ptolemy.vergil.kernel.attributes.TextAttribute']/property[@name='text']" />
        <xsl:variable name="inputs" select="port[@class='ptolemy.actor.TypedIOPort' and property/@name='input' and not(property/@name='output')]" />
        <xsl:variable name="outputs" select="port[@class='ptolemy.actor.TypedIOPort' and property/@name='output' and not(property/@name='input')]" />
        <xsl:variable name="gpio_inputs" select="port[@class='ptolemy.actor.SubscriberPort' and property/@name='input']" />
        <xsl:variable name="gpio_outputs" select="port[@class='ptolemy.actor.PublisherPort' and property/@name='output']" />
        <xsl:variable name="vars" select="property[@class='ptolemy.data.expr.Parameter']" />
        <xsl:variable name="extvars" select="property[@class='ptolemy.actor.parameters.SharedParameter']" />
        <xsl:variable name="alt_vars" select="port[@class='ptolemy.actor.TypedIOPort' and property/@name='output' and property/@name='input']" />
        <xsl:variable name="alt_extvars" select="port[@class='ptolemy.actor.parameters.ParameterPort']" />
        <xsl:variable name="links" select="link"/>
        <xsl:variable name="relations" select="relation"/>

        <xsl:text>#include &lt;freertos/FreeRTOS.h&gt;&#xa;</xsl:text>
        <xsl:text>#include "fsm.hh"&#xa;&#xa;</xsl:text>

        <xsl:call-template name="enum-states">
            <xsl:with-param name="fsm" select="$fsm" />
            <xsl:with-param name="states" select="$states" />
        </xsl:call-template>

        <xsl:call-template name="fsm-class-declaration">
            <xsl:with-param name="fsm" select="$fsm" />
            <xsl:with-param name="funcs" select="$funcs" />
            <xsl:with-param name="inputs" select="$inputs" />
            <xsl:with-param name="outputs" select="$outputs" />
            <xsl:with-param name="gpio_inputs" select="$gpio_inputs" />
            <xsl:with-param name="gpio_outputs" select="$gpio_outputs" />
            <xsl:with-param name="vars" select="$vars" />
            <xsl:with-param name="extvars" select="$extvars" />
            <xsl:with-param name="alt_vars" select="$alt_vars" />
            <xsl:with-param name="alt_extvars" select="$alt_extvars" />
            <xsl:with-param name="links" select="$links"/>
            <xsl:with-param name="relations" select="$relations"/>
        </xsl:call-template>        
    </xsl:template>

    <xsl:template name="enum-states">
        <xsl:param name="fsm"/>
        <xsl:param name="states"/>
        <xsl:text>enum class </xsl:text>
        <xsl:call-template name="first-capital"><xsl:with-param name="text" select="$fsm"/></xsl:call-template>
        <xsl:text> { </xsl:text>
        <xsl:for-each select="$states">
            <xsl:call-template name="capitalize"><xsl:with-param name="text" select="@name"/></xsl:call-template>
            <xsl:if test="position()!=last()">, </xsl:if>
        </xsl:for-each>
        <xsl:text> };&#xa;&#xa;</xsl:text>
    </xsl:template>


    <!-- FSM Class declaration -->
    <xsl:template name="fsm-class-declaration">
        <xsl:param name="fsm"/>
        <xsl:param name="funcs"/>
        <xsl:param name="inputs"/>
        <xsl:param name="outputs"/>
        <xsl:param name="gpio_inputs"/>
        <xsl:param name="gpio_outputs"/>
        <xsl:param name="vars" />
        <xsl:param name="extvars" />
        <xsl:param name="alt_vars" />
        <xsl:param name="alt_extvars" />
        <xsl:param name="links" />
        <xsl:param name="relations" />

        <!-- Head declaration -->
        <xsl:text>class </xsl:text>
        <xsl:value-of select="$fsm"/>
        <xsl:text> : public fsm&lt;</xsl:text>
        <xsl:call-template name="first-capital"><xsl:with-param name="text" select="$fsm"/></xsl:call-template>
        <xsl:text>, </xsl:text><xsl:value-of select="$fsm"/>
        <xsl:text>&gt; {&#xa;&#xa;</xsl:text>

        <!-- GPIO constants -->
        <xsl:for-each select="$gpio_inputs|$gpio_outputs">
            <xsl:text>    const gpio_num_t </xsl:text>
            <xsl:call-template name="capitalize"><xsl:with-param name="text" select="@name"/></xsl:call-template>
            <xsl:text> = GPIO_NUM_</xsl:text>
            <xsl:value-of select="property[@name='channel']/@value"/>
            <xsl:text>;&#xa;</xsl:text>
        </xsl:for-each>
        <xsl:text>&#xa;</xsl:text>

        <!-- Private functions -->
        <xsl:if test="count($funcs)>0">
            <xsl:for-each select="$funcs">
                <xsl:text>    </xsl:text>
                <xsl:value-of select="@value"/>
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>

        <xsl:text>public:&#xa;</xsl:text>

        <!-- GPIO Input declarations -->
        <xsl:for-each select="$gpio_inputs">
            <xsl:text>    gpio_input </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>;&#xa;</xsl:text>
        </xsl:for-each>

        <!-- Input declarations -->
        <xsl:for-each select="$inputs">
            <xsl:text>    input&lt;</xsl:text>
            <xsl:call-template name="cpp-type"><xsl:with-param name="type" select="property[@name='_type']/@value"/></xsl:call-template>
            <xsl:text>&gt; </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>;&#xa;</xsl:text>
        </xsl:for-each>

        <xsl:text>&#xa;public:&#xa;</xsl:text>

        <!-- GPIO Output declarations -->
        <xsl:for-each select="$gpio_outputs">
            <xsl:text>    gpio_output </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>;&#xa;</xsl:text>
        </xsl:for-each>

        <!-- Output declarations -->
        <xsl:for-each select="$outputs">
            <xsl:text>    output&lt;</xsl:text>
            <xsl:call-template name="cpp-type"><xsl:with-param name="type" select="property[@name='_type']/@value"/></xsl:call-template>
            <xsl:text>&gt; </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>;&#xa;</xsl:text>
        </xsl:for-each>

        <xsl:text>&#xa;protected:&#xa;</xsl:text>

        <!-- State variables -->
        <xsl:for-each select="$vars|$extvars">
            <xsl:text>    decltype(</xsl:text>
            <xsl:value-of select="@value"/>
            <xsl:text>) </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>;&#xa;</xsl:text>
        </xsl:for-each>
        <xsl:for-each select="$alt_vars|$alt_extvars">
            <xsl:text>    </xsl:text>
            <xsl:call-template name="cpp-type"><xsl:with-param name="type" select="property[@name='_type']/@value"/></xsl:call-template>
            <xsl:text> </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>;&#xa;</xsl:text>
        </xsl:for-each>

        <!-- External outputs connected to inputs -->
        <xsl:for-each select="$inputs">
            <xsl:text>    const output&lt;</xsl:text>
            <xsl:call-template name="cpp-type"><xsl:with-param name="type" select="property[@name='_type']/@value"/></xsl:call-template>
            <xsl:text>&gt;&amp; </xsl:text>
            <xsl:value-of select="concat('_',@name)"/>
            <xsl:text>;&#xa;</xsl:text>
        </xsl:for-each>

        <xsl:text>&#xa;public:&#xa;</xsl:text>

        <!-- Constructor -->
        <xsl:text>    </xsl:text>
        <xsl:value-of select="$fsm"/>
        <xsl:text>(</xsl:text>
        <xsl:for-each select="$inputs">
            <xsl:text>const output&lt;</xsl:text>
            <xsl:call-template name="cpp-type"><xsl:with-param name="type" select="property[@name='_type']/@value"/></xsl:call-template>
            <xsl:text>&gt;&amp; ext_</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:if test="position()!=last() or count($extvars|$alt_extvars)>0">, </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="$extvars">
            <xsl:text>decltype(</xsl:text>
            <xsl:value-of select="@value"/>
            <xsl:text>) ext</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:if test="position()!=last() or count($alt_extvars)>0">, </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="$alt_extvars">
            <xsl:call-template name="cpp-type"><xsl:with-param name="type" select="property[@name='_type']/@value"/></xsl:call-template>
            <xsl:text> ext</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:if test="position()!=last()">, </xsl:if>
        </xsl:for-each>
        <xsl:text>) : fsm_type {&#xa;</xsl:text>
        <xsl:for-each select="$relations">
            <xsl:variable name="currentRelation" select="@name"/>
            <xsl:variable name="currentLinks" select="$links[@relation=$currentRelation]"/>
            <xsl:variable name="fromNode" select="substring-before($currentLinks/@port[substring-after(.,'.')='outgoingPort'],'.')"/>
            <xsl:variable name="toNode" select="substring-before($currentLinks/@port[substring-after(.,'.')='incomingPort'],'.')"/>

            <xsl:text>        transition{&#xa;</xsl:text>
            <!-- From state -->
            <xsl:text>            </xsl:text>
            <xsl:call-template name="first-capital"><xsl:with-param name="text" select="$fsm"/></xsl:call-template>
            <xsl:text>::</xsl:text>
            <xsl:call-template name="capitalize"><xsl:with-param name="text" select="$fromNode"/></xsl:call-template>
            <!-- Guard -->
            <xsl:text>, [this](){ return </xsl:text>
            <xsl:value-of select="property[@name='guardExpression']/@value"/>
            <xsl:text>; },&#xa;</xsl:text> 
            <!-- To state -->
            <xsl:text>            </xsl:text>
            <xsl:call-template name="first-capital"><xsl:with-param name="text" select="$fsm"/></xsl:call-template>
            <xsl:text>::</xsl:text>
            <xsl:call-template name="capitalize"><xsl:with-param name="text" select="$toNode"/></xsl:call-template>
            <!-- output function -->
            <xsl:text>, [this](){ </xsl:text>
            <xsl:value-of select="property[@name='outputActions']/@value"/>
            <xsl:text>; </xsl:text>
            <xsl:value-of select="property[@name='setActions']/@value"/>
            <xsl:text>; }&#xa;        },&#xa;</xsl:text> 
        </xsl:for-each>
        <xsl:text>    },&#xa;</xsl:text>
        
        <!-- GPIO Input initializations -->
        <xsl:for-each select="$gpio_inputs">
            <xsl:text>    </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>{</xsl:text>
            <xsl:call-template name="capitalize"><xsl:with-param name="text" select="@name"/></xsl:call-template>
            <xsl:text>}</xsl:text>
            <xsl:if test="position()!=last() or count($inputs|$gpio_outputs|$outputs|$vars|$extvars|$inputs)>0">,&#xa;</xsl:if>
        </xsl:for-each>
    
        <!-- Input initializations -->
        <xsl:for-each select="$inputs">
            <xsl:text>    </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>{[this](){ return _</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>; }}</xsl:text>
            <xsl:if test="position()!=last() or count($gpio_outputs|$outputs|$vars|$extvars|$inputs)>0">,&#xa;</xsl:if>
        </xsl:for-each>

        <!-- GPIO Output initializations -->
        <xsl:for-each select="$gpio_outputs">
            <xsl:text>    </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>{</xsl:text>
            <xsl:call-template name="capitalize"><xsl:with-param name="text" select="@name"/></xsl:call-template>
            <xsl:text>}</xsl:text>
            <xsl:if test="position()!=last() or count($outputs|$vars|$extvars|$inputs)>0">,&#xa;</xsl:if>
        </xsl:for-each>

        <!-- Output initializations -->
        <xsl:for-each select="$outputs">
            <xsl:text>    </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>{}</xsl:text>
            <xsl:if test="position()!=last() or count($vars|$alt_vars|$extvars|$alt_extvars|$inputs)>0">,&#xa;</xsl:if>
        </xsl:for-each>
    
        <!-- State variable initialization -->
        <xsl:for-each select="$vars">    
            <xsl:text>    </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="@value"/>
            <xsl:text>}</xsl:text>
            <xsl:if test="position()!=last() or count($alt_vars|$extvars|$alt_extvars|$inputs)>0">,&#xa;</xsl:if>
        </xsl:for-each>

        <xsl:for-each select="$alt_vars">    
            <xsl:text>    </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="property[@name='defaultValue']/@value"/>
            <xsl:text>}</xsl:text>
            <xsl:if test="position()!=last() or count($extvars|$alt_extvars|$inputs)>0">,&#xa;</xsl:if>
        </xsl:for-each>

        <xsl:for-each select="$extvars">    
            <xsl:text>    </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>{ext</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>}</xsl:text>
            <xsl:if test="position()!=last() or count($alt_extvars|$inputs)>0">,&#xa;</xsl:if>
        </xsl:for-each>
    
        <xsl:for-each select="$alt_extvars">
            <xsl:text>    </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>{ext</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>}</xsl:text>
            <xsl:if test="position()!=last() or count($inputs)>0">,&#xa;</xsl:if>
        </xsl:for-each>

        <!-- External outputs connected to inputs -->
        <xsl:for-each select="$inputs">
            <xsl:text>    </xsl:text>
            <xsl:value-of select="concat('_',@name)"/>
            <xsl:text>{ext_</xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text>}</xsl:text>
            <xsl:if test="position()!=last()">,&#xa;</xsl:if>
        </xsl:for-each>
        <xsl:text>&#xa;    {}&#xa;};</xsl:text>
    </xsl:template>


    <!-- Plantillas auxiliares -->

    <xsl:template name="first-capital">
        <xsl:param name="text"/>
        <xsl:call-template name="capitalize"><xsl:with-param name="text" select="substring($text,1,1)"/></xsl:call-template>
        <xsl:value-of select="substring($text,2)"/>
    </xsl:template>

    <xsl:template name="capitalize">
        <xsl:param name="text"/>
        <xsl:value-of select="translate($text,$lowercase,$uppercase)"/>
    </xsl:template>

    <xsl:template name="cpp-type">
        <xsl:param name="type"/>
        <xsl:choose>
        <xsl:when test="$type='boolean'">bool</xsl:when>
        <xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>