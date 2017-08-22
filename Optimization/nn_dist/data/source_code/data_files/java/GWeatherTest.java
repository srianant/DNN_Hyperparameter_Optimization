/**
 * The MIT License
 * Copyright (c) 2014 Ilkka Seppälä
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package com.iluwatar.observer.generic;

import com.iluwatar.observer.StdOutTest;
import com.iluwatar.observer.WeatherObserver;
import com.iluwatar.observer.WeatherType;

import org.junit.Test;
import org.mockito.InOrder;

import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.verifyZeroInteractions;

/**
 * Date: 12/27/15 - 11:08 AM
 *
 * @author Jeroen Meulemeester
 */
public class GWeatherTest extends StdOutTest {

  /**
   * Add a {@link WeatherObserver}, verify if it gets notified of a weather change, remove the
   * observer again and verify that there are no more notifications.
   */
  @Test
  public void testAddRemoveObserver() {
    final Race observer = mock(Race.class);

    final GWeather weather = new GWeather();
    weather.addObserver(observer);
    verifyZeroInteractions(observer);

    weather.timePasses();
    verify(getStdOutMock()).println("The weather changed to rainy.");
    verify(observer).update(weather, WeatherType.RAINY);

    weather.removeObserver(observer);
    weather.timePasses();
    verify(getStdOutMock()).println("The weather changed to windy.");

    verifyNoMoreInteractions(observer, getStdOutMock());
  }

  /**
   * Verify if the weather passes in the order of the {@link WeatherType}s
   */
  @Test
  public void testTimePasses() {
    final Race observer = mock(Race.class);
    final GWeather weather = new GWeather();
    weather.addObserver(observer);

    final InOrder inOrder = inOrder(observer, getStdOutMock());
    final WeatherType[] weatherTypes = WeatherType.values();
    for (int i = 1; i < 20; i++) {
      weather.timePasses();
      inOrder.verify(observer).update(weather, weatherTypes[i % weatherTypes.length]);
    }

    verifyNoMoreInteractions(observer);
  }

}