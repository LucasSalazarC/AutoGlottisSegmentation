classdef pPoint < handle
    %PPOINT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        point
        XData
        YData
        isStartingPoint
        isEndingPoint
        trailingPoint
        trailingLine
        followingPoint
        followingLine
    end
    
    methods
        function obj = pPoint(point, isStartingPoint, trailingPoint, trailingLine, followingPoint, followingLine)
            if nargin ~= 0
                obj.point = point;
                obj.XData = point.XData;
                obj.YData = point.YData;
                obj.isStartingPoint = isStartingPoint;
                obj.isEndingPoint = false;

                if nargin >= 4
                    obj.trailingPoint = trailingPoint;
                    obj.trailingLine = trailingLine;
                end
                if nargin == 6
                    obj.followingPoint = followingPoint;
                    obj.followingLine = followingLine;
                end
            end
        end
        
        function [x,y] = movePoint(obj, x, y)
            obj.point.XData = x;
            obj.point.YData = y;
            obj.XData = x;
            obj.YData = y;
        end
    end
    
end

