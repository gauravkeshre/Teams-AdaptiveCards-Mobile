/* ----------------------------------------------------------------------------
 * This file was automatically generated by SWIG (http://www.swig.org).
 * Version 4.0.2
 *
 * Do not make changes to this file unless you know what you are doing--modify
 * the SWIG interface file instead.
 * ----------------------------------------------------------------------------- */

package io.adaptivecards.objectmodel;

public class SpacingConfig {
  private transient long swigCPtr;
  protected transient boolean swigCMemOwn;

  protected SpacingConfig(long cPtr, boolean cMemoryOwn) {
    swigCMemOwn = cMemoryOwn;
    swigCPtr = cPtr;
  }

  protected static long getCPtr(SpacingConfig obj) {
    return (obj == null) ? 0 : obj.swigCPtr;
  }

  @SuppressWarnings("deprecation")
  protected void finalize() {
    delete();
  }

  public synchronized void delete() {
    if (swigCPtr != 0) {
      if (swigCMemOwn) {
        swigCMemOwn = false;
        AdaptiveCardObjectModelJNI.delete_SpacingConfig(swigCPtr);
      }
      swigCPtr = 0;
    }
  }

  public void setSmallSpacing(long value) {
    AdaptiveCardObjectModelJNI.SpacingConfig_smallSpacing_set(swigCPtr, this, value);
  }

  public long getSmallSpacing() {
    return AdaptiveCardObjectModelJNI.SpacingConfig_smallSpacing_get(swigCPtr, this);
  }

  public void setDefaultSpacing(long value) {
    AdaptiveCardObjectModelJNI.SpacingConfig_defaultSpacing_set(swigCPtr, this, value);
  }

  public long getDefaultSpacing() {
    return AdaptiveCardObjectModelJNI.SpacingConfig_defaultSpacing_get(swigCPtr, this);
  }

  public void setMediumSpacing(long value) {
    AdaptiveCardObjectModelJNI.SpacingConfig_mediumSpacing_set(swigCPtr, this, value);
  }

  public long getMediumSpacing() {
    return AdaptiveCardObjectModelJNI.SpacingConfig_mediumSpacing_get(swigCPtr, this);
  }

  public void setLargeSpacing(long value) {
    AdaptiveCardObjectModelJNI.SpacingConfig_largeSpacing_set(swigCPtr, this, value);
  }

  public long getLargeSpacing() {
    return AdaptiveCardObjectModelJNI.SpacingConfig_largeSpacing_get(swigCPtr, this);
  }

  public void setExtraLargeSpacing(long value) {
    AdaptiveCardObjectModelJNI.SpacingConfig_extraLargeSpacing_set(swigCPtr, this, value);
  }

  public long getExtraLargeSpacing() {
    return AdaptiveCardObjectModelJNI.SpacingConfig_extraLargeSpacing_get(swigCPtr, this);
  }

  public void setPaddingSpacing(long value) {
    AdaptiveCardObjectModelJNI.SpacingConfig_paddingSpacing_set(swigCPtr, this, value);
  }

  public long getPaddingSpacing() {
    return AdaptiveCardObjectModelJNI.SpacingConfig_paddingSpacing_get(swigCPtr, this);
  }

  public void setExtraSmallSpacing(long value) {
    AdaptiveCardObjectModelJNI.SpacingConfig_extraSmallSpacing_set(swigCPtr, this, value);
  }

  public long getExtraSmallSpacing() {
    return AdaptiveCardObjectModelJNI.SpacingConfig_extraSmallSpacing_get(swigCPtr, this);
  }

  public static SpacingConfig Deserialize(JsonValue json, SpacingConfig defaultValue) {
    return new SpacingConfig(AdaptiveCardObjectModelJNI.SpacingConfig_Deserialize(JsonValue.getCPtr(json), json, SpacingConfig.getCPtr(defaultValue), defaultValue), true);
  }

  public SpacingConfig() {
    this(AdaptiveCardObjectModelJNI.new_SpacingConfig(), true);
  }

}
